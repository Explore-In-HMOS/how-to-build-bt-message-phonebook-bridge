import { BluetoothSocketManager } from './BluetoothSocketManager';
import { PbapManager } from './PbapManager';
import { MapManager } from './MapManager';
import { ConnState, SyncState, PairedDevice, Contact, Message } from '../model/BridgeTypes';
import { StoreKeys } from '../common/StoreKeys';
import { TimeUtil } from '../common/TimeUtil';
import { Logger } from '../common/Logger';

/**
 * Singleton orchestrator (the "ViewModel" of section 3.3.5).
 *
 * It owns the three profile managers and is the single writer of the reactive
 * state held in AppStorage. UI pages never touch Bluetooth directly — they call
 * BridgeService and bind to AppStorage keys.
 *
 * Error handling follows 3.3.6: connect retries with backoff, and a failed
 * sync leaves whatever partial/cached data exists in place.
 */
export class BridgeService {
  private static instance: BridgeService | null = null;

  private socketManager: BluetoothSocketManager;
  private pbapManager: PbapManager;
  private mapManager: MapManager;

  private static readonly MAX_RETRIES: number = 3;
  private static readonly MAX_CONTACTS: number = 500;
  private static readonly MAX_MESSAGES: number = 50;

  private constructor() {
    this.socketManager = new BluetoothSocketManager();
    this.pbapManager = new PbapManager(this.socketManager);
    this.mapManager = new MapManager(this.socketManager);
  }

  static get(): BridgeService {
    if (BridgeService.instance === null) {
      BridgeService.instance = new BridgeService();
    }
    return BridgeService.instance;
  }

  /** Seed AppStorage with defaults. Call once at app start. */
  initStore(): void {
    AppStorage.setOrCreate<string>(StoreKeys.CONN_STATE, ConnState.DISCONNECTED);
    AppStorage.setOrCreate<string>(StoreKeys.CONTACT_SYNC, SyncState.IDLE);
    AppStorage.setOrCreate<string>(StoreKeys.MESSAGE_SYNC, SyncState.IDLE);
    AppStorage.setOrCreate<Contact[]>(StoreKeys.CONTACTS, []);
    AppStorage.setOrCreate<Message[]>(StoreKeys.MESSAGES, []);
    AppStorage.setOrCreate<string>(StoreKeys.SELECTED_DEVICE, '');
    AppStorage.setOrCreate<string>(StoreKeys.LAST_CONTACT_SYNC, 'never');
    AppStorage.setOrCreate<string>(StoreKeys.LAST_MESSAGE_SYNC, 'never');
    AppStorage.setOrCreate<string>(StoreKeys.STATUS_TEXT, 'Not connected');
  }

  listPairedDevices(): PairedDevice[] {
    this.socketManager.ensureBluetoothOn();
    return this.socketManager.getPairedDevices();
  }

  isConnected(): boolean {
    return this.socketManager.isConnected();
  }

  /**
   * Connect to a phone over SPP with exponential backoff (3.3.1 error handling).
   * Updates CONN_STATE / STATUS_TEXT throughout.
   */
  async connect(device: PairedDevice): Promise<boolean> {
    AppStorage.setOrCreate<string>(StoreKeys.SELECTED_DEVICE, device.name);
    AppStorage.setOrCreate<string>(StoreKeys.CONN_STATE, ConnState.CONNECTING);
    AppStorage.setOrCreate<string>(StoreKeys.STATUS_TEXT, `Connecting to ${device.name}…`);

    let attempt: number = 0;
    let delay: number = 500;
    while (attempt < BridgeService.MAX_RETRIES) {
      try {
        await this.socketManager.connect(device.deviceId);
        AppStorage.setOrCreate<string>(StoreKeys.CONN_STATE, ConnState.CONNECTED);
        AppStorage.setOrCreate<string>(StoreKeys.STATUS_TEXT, `Connected to ${device.name}`);
        Logger.info(`Connected to ${device.name}`);
        return true;
      } catch (e) {
        attempt++;
        Logger.warn(`Connect attempt ${attempt} failed, retrying in ${delay}ms`);
        if (attempt >= BridgeService.MAX_RETRIES) {
          break;
        }
        await BridgeService.sleep(delay);
        delay = delay * 2; // exponential backoff
      }
    }

    AppStorage.setOrCreate<string>(StoreKeys.CONN_STATE, ConnState.ERROR);
    AppStorage.setOrCreate<string>(StoreKeys.STATUS_TEXT, 'Connection failed — tap to retry');
    return false;
  }

  disconnect(): void {
    this.socketManager.close();
    AppStorage.setOrCreate<string>(StoreKeys.CONN_STATE, ConnState.DISCONNECTED);
    AppStorage.setOrCreate<string>(StoreKeys.STATUS_TEXT, 'Disconnected');
  }

  /** Pull contacts (PBAP). Falls back to demo data offline. */
  async syncContacts(): Promise<void> {
    AppStorage.setOrCreate<string>(StoreKeys.CONTACT_SYNC, SyncState.LOADING);
    try {
      const contacts: Contact[] = await this.pbapManager.pullPhoneBook(BridgeService.MAX_CONTACTS);
      contacts.sort((a: Contact, b: Contact) => a.name.localeCompare(b.name));
      AppStorage.setOrCreate<Contact[]>(StoreKeys.CONTACTS, contacts);
      AppStorage.setOrCreate<string>(StoreKeys.LAST_CONTACT_SYNC, TimeUtil.clock(new Date().getTime()));
      AppStorage.setOrCreate<string>(StoreKeys.CONTACT_SYNC, SyncState.DONE);
      Logger.info(`Synced ${contacts.length} contacts`);
    } catch (e) {
      AppStorage.setOrCreate<string>(StoreKeys.CONTACT_SYNC, SyncState.FAILED);
      Logger.error('syncContacts failed');
    }
  }

  /** Pull messages (MAP). Falls back to demo data offline. */
  async syncMessages(): Promise<void> {
    AppStorage.setOrCreate<string>(StoreKeys.MESSAGE_SYNC, SyncState.LOADING);
    try {
      const messages: Message[] = await this.mapManager.getMessages(BridgeService.MAX_MESSAGES);
      AppStorage.setOrCreate<Message[]>(StoreKeys.MESSAGES, messages);
      AppStorage.setOrCreate<string>(StoreKeys.LAST_MESSAGE_SYNC, TimeUtil.clock(new Date().getTime()));
      AppStorage.setOrCreate<string>(StoreKeys.MESSAGE_SYNC, SyncState.DONE);
      Logger.info(`Synced ${messages.length} messages`);
    } catch (e) {
      AppStorage.setOrCreate<string>(StoreKeys.MESSAGE_SYNC, SyncState.FAILED);
      Logger.error('syncMessages failed');
    }
  }

  private static sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => resolve(), ms);
    });
  }
}
