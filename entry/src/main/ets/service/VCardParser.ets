import { Contact } from '../model/BridgeTypes';

/**
 * Minimal vCard 2.1 / 3.0 parser.
 *
 * PBAP returns phonebook entries as concatenated vCard objects. A real PBAP
 * pull (pullPhoneBook) hands back a string like:
 *
 * This parser is deliberately small: it extracts FN (formatted name), N
 * (structured name fallback), TEL and EMAIL fields. It tolerates the
 * "property;params:value" form by splitting on the first ':' after the
 * property name.
 */
export class VCardParser {
  static parse(raw: string): Contact[] {
    const contacts: Contact[] = [];
    if (!raw || raw.length === 0) {
      return contacts;
    }

    const blocks: string[] = raw.split('BEGIN:VCARD');
    let index: number = 0;
    for (const block of blocks) {
      if (block.indexOf('END:VCARD') < 0) {
        continue;
      }
      const contact: Contact = VCardParser.parseBlock(block, index);
      if (contact.name.length > 0 || contact.phoneNumbers.length > 0) {
        contacts.push(contact);
        index++;
      }
    }
    return contacts;
  }

  private static parseBlock(block: string, index: number): Contact {
    let name: string = '';
    let structuredName: string = '';
    const phones: string[] = [];
    const emails: string[] = [];

    const lines: string[] = block.split('\n');
    for (const rawLine of lines) {
      const line: string = rawLine.trim();
      if (line.length === 0) {
        continue;
      }
      const colon: number = line.indexOf(':');
      if (colon < 0) {
        continue;
      }
      const property: string = line.substring(0, colon).toUpperCase();
      const value: string = line.substring(colon + 1).trim();

      if (property.indexOf('FN') === 0) {
        name = value;
      } else if (property.indexOf('N') === 0 && property.indexOf('FN') !== 0) {
        const parts: string[] = value.split(';');
        const last: string = parts.length > 0 ? parts[0] : '';
        const first: string = parts.length > 1 ? parts[1] : '';
        structuredName = `${first} ${last}`.trim();
      } else if (property.indexOf('TEL') === 0) {
        if (value.length > 0) {
          phones.push(value);
        }
      } else if (property.indexOf('EMAIL') === 0) {
        if (value.length > 0) {
          emails.push(value);
        }
      }
    }

    const finalName: string = name.length > 0 ? name : structuredName;
    return {
      id: `vc_${index}`,
      name: finalName,
      phoneNumbers: phones,
      emails: emails
    };
  }
}
