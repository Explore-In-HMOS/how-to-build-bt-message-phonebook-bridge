import { Contact, Message, PairedDevice } from '../model/BridgeTypes';

/**
 * Offline demo data. The codelab is "offline-first" and is expected to run on
 * an emulator or a watch with no companion phone app. When the SPP request
 * times out (or no device is selected) the managers fall back to this data so
 * the UI is always demonstrable.
 */
export class DemoData {
  static pairedDevices(): PairedDevice[] {
    return [
      { deviceId: '11:22:33:AA:BB:CC', name: 'My Phone (Demo)' },
      { deviceId: 'AA:BB:CC:11:22:33', name: 'Pixel 8' }
    ];
  }

  static contacts(): Contact[] {
    return [
      { id: 'c1', name: 'Alice Anderson', phoneNumbers: ['+1 202 555 0143'], emails: ['alice@example.com'] },
      { id: 'c2', name: 'Bob Brown', phoneNumbers: ['+1 202 555 0179', '+1 202 555 0112'], emails: [] },
      { id: 'c3', name: 'Carol Clarke', phoneNumbers: ['+44 20 7946 0958'], emails: ['carol.c@example.com'] },
      { id: 'c4', name: 'David Davis', phoneNumbers: ['+1 415 555 2671'], emails: [] },
      { id: 'c5', name: 'Eve Edwards', phoneNumbers: ['+1 650 555 8841'], emails: ['eve@example.com'] },
      { id: 'c6', name: 'Frank Foster', phoneNumbers: ['+1 312 555 0190'], emails: [] }
    ];
  }

  static messages(): Message[] {
    const now: number = new Date().getTime();
    const min: number = 60 * 1000;
    return [
      { id: 'm1', sender: 'Alice Anderson', content: 'Are we still on for lunch at noon?', timestamp: now - 3 * min, read: false, type: 'SMS' },
      { id: 'm2', sender: '+1 650 555 8841', content: 'Your verification code is 482913.', timestamp: now - 28 * min, read: false, type: 'SMS' },
      { id: 'm3', sender: 'Bob Brown', content: 'Sent you the files, check email.', timestamp: now - 95 * min, read: true, type: 'SMS' },
      { id: 'm4', sender: 'Carol Clarke', content: 'Happy birthday! Hope you have a great day.', timestamp: now - 5 * 60 * min, read: true, type: 'MMS' },
      { id: 'm5', sender: 'Bank', content: 'A payment of $42.00 was made on your card.', timestamp: now - 20 * 60 * min, read: true, type: 'SMS' }
    ];
  }
}
