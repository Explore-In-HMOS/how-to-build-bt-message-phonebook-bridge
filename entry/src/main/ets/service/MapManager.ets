import { BluetoothSocketManager } from './BluetoothSocketManager';
import { Message, MessagesEnvelope, BridgeCommand } from '../model/BridgeTypes';
import { DemoData } from './DemoData';
import { Logger } from '../common/Logger';

/**
 * Message sync (MAP) — section 3.3.3.
 *
 * As with PBAP, there is no public MAP client, so messages are requested from
 * the companion phone app over SPP. The phone answers with a JSON
 * MessagesEnvelope { "type":"MESSAGES", "data":[ ... ] }. On timeout / no
 * connection we return demo messages.
 */
export class MapManager {
  private socketManager: BluetoothSocketManager;
  private static readonly TIMEOUT_MS: number = 8000;

  constructor(socketManager: BluetoothSocketManager) {
    this.socketManager = socketManager;
  }

  async getMessages(maxCount: number): Promise<Message[]> {
    if (!this.socketManager.isConnected()) {
      Logger.warn('MAP: not connected, using demo messages');
      return MapManager.sortNewestFirst(DemoData.messages());
    }

    const cmd: BridgeCommand = { cmd: 'GET_MESSAGES', maxCount: maxCount, folder: 'telecom/msg/inbox' };
    try {
      const line: string = await this.socketManager.request(cmd, 'MESSAGES', MapManager.TIMEOUT_MS);
      return MapManager.parseReply(line);
    } catch (e) {
      const err = e as Error;
      Logger.error(`MAP fetch failed: ${err.message} — falling back to demo`);
      return MapManager.sortNewestFirst(DemoData.messages());
    }
  }

  private static parseReply(line: string): Message[] {
    try {
      const envelope: MessagesEnvelope = JSON.parse(line.trim()) as MessagesEnvelope;
      if (envelope && envelope.data) {
        return MapManager.sortNewestFirst(MapManager.normalize(envelope.data));
      }
    } catch (e) {
      Logger.error('MAP: could not parse reply as JSON');
    }
    return [];
  }

  private static normalize(items: Message[]): Message[] {
    const out: Message[] = [];
    let i: number = 0;
    for (const m of items) {
      out.push({
        id: m.id && m.id.length > 0 ? m.id : `m_${i}`,
        sender: m.sender ? m.sender : 'Unknown',
        content: m.content ? m.content : '',
        timestamp: m.timestamp ? m.timestamp : 0,
        read: m.read === true,
        type: m.type ? m.type : 'SMS'
      });
      i++;
    }
    return out;
  }

  private static sortNewestFirst(items: Message[]): Message[] {
    return items.sort((a: Message, b: Message) => b.timestamp - a.timestamp);
  }
}
