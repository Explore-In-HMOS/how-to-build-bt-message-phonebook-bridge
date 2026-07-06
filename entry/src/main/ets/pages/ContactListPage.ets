import { BridgeService } from '../service/BridgeService';
import { Contact, SyncState } from '../model/BridgeTypes';
import { StoreKeys } from '../common/StoreKeys';
import { AppTheme } from '../common/AppTheme';

/**
 * Contact list (3.3.4 screen 2). Alphabetically sorted (sorting done in
 * BridgeService). Tapping an item stores it and opens the detail page.
 */
@Component
export struct ContactListPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink(StoreKeys.CONTACTS) contacts: Contact[] = [];
  @StorageProp(StoreKeys.CONTACT_SYNC) syncState: string = SyncState.IDLE;

  private bridge: BridgeService = BridgeService.get();

  aboutToAppear(): void {
    // Auto-sync the first time the list is empty so the page is never blank.
    if (this.contacts.length === 0) {
      this.bridge.syncContacts();
    }
  }

  private initials(name: string): string {
    const parts: string[] = name.trim().split(' ');
    if (parts.length === 0 || parts[0].length === 0) {
      return '?';
    }
    let s: string = parts[0].substring(0, 1);
    if (parts.length > 1 && parts[parts.length - 1].length > 0) {
      s += parts[parts.length - 1].substring(0, 1);
    }
    return s.toUpperCase();
  }

  private openContact(c: Contact): void {
    AppStorage.setOrCreate<Contact>(StoreKeys.SELECTED_CONTACT, c);
    this.pageStack.pushPathByName('ContactDetailPage', null);
  }

  build() {
    NavDestination() {
      Column() {
        Row({ space: 6 }) {
          Text('Contacts')
            .fontSize(AppTheme.TITLE_FS)
            .fontColor(AppTheme.TEXT)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          Text(`${this.contacts.length}`)
            .fontSize(AppTheme.SMALL_FS)
            .fontColor(AppTheme.TEXT_DIM)
        }
        .width('100%')
        .margin({ top: 8, bottom: 6 })

        if (this.syncState === SyncState.LOADING && this.contacts.length === 0) {
          Column({ space: 10 }) {
            LoadingProgress().width(36).height(36).color(AppTheme.PRIMARY)
            Text('Syncing…').fontSize(AppTheme.SMALL_FS).fontColor(AppTheme.TEXT_DIM)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.contacts.length === 0) {
          Text('No contacts yet')
            .fontSize(AppTheme.BODY_FS)
            .fontColor(AppTheme.TEXT_DIM)
            .layoutWeight(1)
        } else {
          List({ space: AppTheme.GAP }) {
            ForEach(this.contacts, (item: Contact) => {
              ListItem() {
                Row({ space: 10 }) {
                  // Avatar bubble with initials
                  Stack() {
                    Circle({ width: 34, height: 34 }).fill(AppTheme.CARD_ACCENT)
                    Text(this.initials(item.name))
                      .fontSize(13)
                      .fontColor(AppTheme.TEXT)
                      .fontWeight(FontWeight.Medium)
                  }
                  Column() {
                    Text(item.name)
                      .fontSize(AppTheme.BODY_FS)
                      .fontColor(AppTheme.TEXT)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(item.phoneNumbers.length > 0 ? item.phoneNumbers[0] : 'No number')
                      .fontSize(AppTheme.SMALL_FS)
                      .fontColor(AppTheme.TEXT_DIM)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .padding(10)
              }
              .backgroundColor(AppTheme.CARD)
              .borderRadius(AppTheme.RADIUS)
              .onClick(() => this.openContact(item))
            }, (item: Contact) => item.id)
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .layoutWeight(1)
          .width('100%')
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: AppTheme.SCREEN_PAD, right: AppTheme.SCREEN_PAD })
    }
    .hideTitleBar(true)
    .backgroundColor(AppTheme.BG)
  }
}
