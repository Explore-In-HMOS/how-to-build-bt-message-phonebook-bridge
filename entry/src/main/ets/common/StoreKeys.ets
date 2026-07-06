/**
 * Centralised AppStorage keys. The BridgeService writes to these and the
 * router pages bind to them with @StorageLink / @StorageProp, giving us a
 * single reactive ViewModel that survives page navigation.
 */
export class StoreKeys {
  static readonly CONN_STATE: string = 'connState';
  static readonly CONTACT_SYNC: string = 'contactSyncState';
  static readonly MESSAGE_SYNC: string = 'messageSyncState';
  static readonly CONTACTS: string = 'contacts';
  static readonly MESSAGES: string = 'messages';
  static readonly SELECTED_DEVICE: string = 'selectedDevice';
  static readonly LAST_CONTACT_SYNC: string = 'lastContactSync';
  static readonly LAST_MESSAGE_SYNC: string = 'lastMessageSync';
  static readonly STATUS_TEXT: string = 'statusText';
  // Selected items for the detail pages (passed via storage, not router params,
  // to keep complex objects intact).
  static readonly SELECTED_CONTACT: string = 'selectedContact';
  static readonly SELECTED_MESSAGE: string = 'selectedMessage';
}
