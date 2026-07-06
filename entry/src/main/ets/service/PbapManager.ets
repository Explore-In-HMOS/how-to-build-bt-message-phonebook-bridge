import { BluetoothSocketManager } from './BluetoothSocketManager';
import { Contact, ContactsEnvelope, BridgeCommand } from '../model/BridgeTypes';
import { VCardParser } from './VCardParser';
import { DemoData } from './DemoData';
import { Logger } from '../common/Logger';

/**
 * Phonebook sync (PBAP) — section 3.3.2.
 *
 * HarmonyOS does not expose a public PBAP client today, so this manager
 * implements the same outcome over the established SPP channel: it asks the
 * companion phone app for the "telecom/pb" folder and parses the reply.
 *
 * The phone may answer in either of two shapes:
 *   1. A JSON ContactsEnvelope  { "type":"CONTACTS", "data":[ ... ] }
 *   2. Raw vCard text (BEGIN:VCARD ...), which we run through VCardParser.
 *
 * If no phone is connected or the request times out, demo contacts are
 * returned so the offline-first UI still has something to show.
 */
export class PbapManager {
  private socketManager: BluetoothSocketManager;
  private static readonly TIMEOUT_MS: number = 8000;

  constructor(socketManager: BluetoothSocketManager) {
    this.socketManager = socketManager;
  }

  async pullPhoneBook(maxCount: number): Promise<Contact[]> {
    if (!this.socketManager.isConnected()) {
      Logger.warn('PBAP: not connected, using demo contacts');
      return DemoData.contacts();
    }

    const cmd: BridgeCommand = { cmd: 'GET_CONTACTS', maxCount: maxCount, folder: 'telecom/pb' };
    try {
      const line: string = await this.socketManager.request(cmd, 'CONTACTS', PbapManager.TIMEOUT_MS);
      return PbapManager.parseReply(line);
    } catch (e) {
      const err = e as Error;
      Logger.error(`PBAP pull failed: ${err.message} — falling back to demo`);
      return DemoData.contacts();
    }
  }

  private static parseReply(line: string): Contact[] {
    const trimmed: string = line.trim();
    // vCard payload?
    if (trimmed.indexOf('BEGIN:VCARD') >= 0) {
      return VCardParser.parse(trimmed);
    }
    // Otherwise JSON envelope.
    try {
      const envelope: ContactsEnvelope = JSON.parse(trimmed) as ContactsEnvelope;
      if (envelope && envelope.data) {
        return PbapManager.normalize(envelope.data);
      }
    } catch (e) {
      Logger.error('PBAP: could not parse reply as JSON');
    }
    return [];
  }

  /** Guard against missing optional arrays in the wire data. */
  private static normalize(items: Contact[]): Contact[] {
    const out: Contact[] = [];
    let i: number = 0;
    for (const c of items) {
      out.push({
        id: c.id && c.id.length > 0 ? c.id : `c_${i}`,
        name: c.name ? c.name : 'Unknown',
        phoneNumbers: c.phoneNumbers ? c.phoneNumbers : [],
        emails: c.emails ? c.emails : []
      });
      i++;
    }
    return out;
  }
}
