/**
 * Shared data models and enums for the Bluetooth Communication Bridge.
 *
 * These mirror the data structures described in the design document
 * (Contact / Message) and add the connection / sync state machines that
 * the UI binds to.
 */

/** SPP / RFCOMM connection lifecycle. disconnected -> connecting -> connected */
export enum ConnState {
  DISCONNECTED = 'disconnected',
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  ERROR = 'error'
}

/** Sync lifecycle for a data pull (contacts or messages). idle -> loading -> done */
export enum SyncState {
  IDLE = 'idle',
  LOADING = 'loading',
  DONE = 'done',
  FAILED = 'failed'
}

/** A paired phone the watch can connect to. */
export interface PairedDevice {
  deviceId: string; // Bluetooth MAC address
  name: string;
}

/** Phonebook contact synced over PBAP (or the SPP fallback protocol). */
export interface Contact {
  id: string;
  name: string;
  phoneNumbers: string[];
  emails: string[];
}

/** SMS / MMS message synced over MAP (or the SPP fallback protocol). */
export interface Message {
  id: string;
  sender: string;
  content: string;
  timestamp: number; // epoch millis
  read: boolean;
  type: string; // 'SMS' | 'MMS'
}

/**
 * Newline-delimited JSON command protocol used over the SPP channel when a
 * companion phone app is present. The watch sends a Command, the phone
 * replies with an envelope carrying contacts or messages.
 */
export interface BridgeCommand {
  cmd: string; // 'GET_CONTACTS' | 'GET_MESSAGES' | 'PING'
  maxCount?: number;
  folder?: string;
}

export interface ContactsEnvelope {
  type: string; // 'CONTACTS'
  data: Contact[];
}

export interface MessagesEnvelope {
  type: string; // 'MESSAGES'
  data: Message[];
}

/** SPP Serial Port Profile UUID. */
export const SPP_UUID: string = '00001101-0000-1000-8000-00805F9B34FB';
