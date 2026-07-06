import { access, connection, socket } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { BridgeCommand, PairedDevice, SPP_UUID } from '../model/BridgeTypes';
import { Logger } from '../common/Logger';

/**
 * Wraps the SPP / RFCOMM Bluetooth socket (3.3.1 of the design).
 *
 * Responsibilities:
 *   - ensure Bluetooth is on (access)
 *   - list paired phones (connection)
 *   - open an SPP client socket and exchange newline-delimited JSON frames
 *
 * A single outstanding request at a time is supported, which is plenty for the
 * watch's "tap to sync" interaction model. All Connectivity Kit calls are
 * wrapped so a missing capability surfaces as a rejected promise rather than a
 * crash, letting the managers fall back to demo data.
 */
export class BluetoothSocketManager {
  private clientNumber: number = -1;
  private connected: boolean = false;
  private rxBuffer: string = '';
  private decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
  private encoder: util.TextEncoder = new util.TextEncoder();

  // Resolver for the in-flight request, keyed by the envelope "type" we expect.
  private pendingType: string = '';
  private pendingResolve: ((line: string) => void) | null = null;
  private pendingReject: ((err: Error) => void) | null = null;
  private pendingTimer: number = -1;

  isConnected(): boolean {
    return this.connected;
  }

  /** Make sure the Bluetooth radio is powered on. */
  ensureBluetoothOn(): boolean {
    try {
      const state: access.BluetoothState = access.getState();
      if (state === access.BluetoothState.STATE_ON) {
        return true;
      }
      access.enableBluetooth();
      Logger.info('Requested Bluetooth enable');
      return false; // turning on is async; caller should retry shortly
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(`ensureBluetoothOn failed: ${err.code} ${err.message}`);
      return false;
    }
  }

  /** Return the phones already paired with this watch. */
  getPairedDevices(): PairedDevice[] {
    const result: PairedDevice[] = [];
    try {
      const ids: string[] = connection.getPairedDevices();
      for (const id of ids) {
        let name: string = id;
        try {
          name = connection.getRemoteDeviceName(id);
        } catch (e) {
          Logger.warn(`getRemoteDeviceName failed for ${id}`);
        }
        result.push({ deviceId: id, name: name && name.length > 0 ? name : id });
      }
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(`getPairedDevices failed: ${err.code} ${err.message}`);
    }
    return result;
  }

  /** Open an SPP client connection to the given device. */
  connect(deviceId: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      const option: socket.SppOptions = {
        uuid: SPP_UUID,
        secure: true,
        type: socket.SppType.SPP_RFCOMM
      };
      try {
        socket.sppConnect(deviceId, option, (err: BusinessError, clientNumber: number) => {
          if (err && err.code !== 0) {
            Logger.error(`sppConnect error: ${err.code} ${err.message}`);
            reject(new Error(`sppConnect failed: ${err.code}`));
            return;
          }
          this.clientNumber = clientNumber;
          this.connected = true;
          this.rxBuffer = '';
          this.attachReader();
          Logger.info(`SPP connected, client=${clientNumber}`);
          resolve();
        });
      } catch (e) {
        const err = e as BusinessError;
        Logger.error(`sppConnect threw: ${err.code} ${err.message}`);
        reject(new Error(`sppConnect threw: ${err.code}`));
      }
    });
  }

  private attachReader(): void {
    try {
      socket.on('sppRead', this.clientNumber, (data: ArrayBuffer) => {
        this.onChunk(data);
      });
    } catch (e) {
      Logger.error('attach sppRead failed');
    }
  }

  private onChunk(data: ArrayBuffer): void {
    let text: string = '';
    try {
      text = this.decoder.decodeToString(new Uint8Array(data));
    } catch (e) {
      Logger.warn('decode chunk failed');
      return;
    }
    this.rxBuffer += text;

    // Frames are newline-delimited JSON. Process every complete line.
    let nl: number = this.rxBuffer.indexOf('\n');
    while (nl >= 0) {
      const line: string = this.rxBuffer.substring(0, nl).trim();
      this.rxBuffer = this.rxBuffer.substring(nl + 1);
      if (line.length > 0) {
        this.dispatchLine(line);
      }
      nl = this.rxBuffer.indexOf('\n');
    }
  }

  private dispatchLine(line: string): void {
    if (this.pendingResolve === null) {
      return;
    }
    // Only resolve when the frame carries the type we asked for.
    if (this.pendingType.length === 0 || line.indexOf(`"${this.pendingType}"`) >= 0) {
      const resolve = this.pendingResolve;
      this.clearPending();
      resolve(line);
    }
  }

  /**
   * Send a command frame and await the matching reply frame.
   * @param expectedType the envelope "type" field expected in the reply
   * @param timeoutMs reject after this long with no matching reply
   */
  request(cmd: BridgeCommand, expectedType: string, timeoutMs: number): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      if (!this.connected) {
        reject(new Error('not connected'));
        return;
      }
      if (this.pendingResolve !== null) {
        reject(new Error('another request is in flight'));
        return;
      }

      this.pendingType = expectedType;
      this.pendingResolve = resolve;
      this.pendingReject = reject;
      this.pendingTimer = setTimeout(() => {
        const rej = this.pendingReject;
        this.clearPending();
        if (rej !== null) {
          rej(new Error('request timed out'));
        }
      }, timeoutMs);

      const payload: string = JSON.stringify(cmd) + '\n';
      try {
        const bytes: Uint8Array = this.encoder.encodeInto(payload);
        socket.sppWrite(this.clientNumber, bytes.buffer as ArrayBuffer);
        Logger.info(`Sent command: ${cmd.cmd}`);
      } catch (e) {
        const err = e as BusinessError;
        const rej = this.pendingReject;
        this.clearPending();
        if (rej !== null) {
          rej(new Error(`sppWrite failed: ${err.code}`));
        }
      }
    });
  }

  private clearPending(): void {
    if (this.pendingTimer !== -1) {
      clearTimeout(this.pendingTimer);
      this.pendingTimer = -1;
    }
    this.pendingType = '';
    this.pendingResolve = null;
    this.pendingReject = null;
  }

  /** Close the SPP socket and detach listeners. */
  close(): void {
    if (this.clientNumber !== -1) {
      try {
        socket.off('sppRead', this.clientNumber);
      } catch (e) {
        Logger.warn('socket.off failed');
      }
      try {
        socket.sppCloseClientSocket(this.clientNumber);
      } catch (e) {
        Logger.warn('sppCloseClientSocket failed');
      }
    }
    this.clientNumber = -1;
    this.connected = false;
    this.rxBuffer = '';
    this.clearPending();
    Logger.info('SPP closed');
  }
}
