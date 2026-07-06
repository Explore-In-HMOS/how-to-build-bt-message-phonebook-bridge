import { promptAction } from '@kit.ArkUI';
import { BridgeService } from '../service/BridgeService';
import { ConnState, SyncState } from '../model/BridgeTypes';
import { StoreKeys } from '../common/StoreKeys';
import { AppTheme } from '../common/AppTheme';
import { DevicePickerPage } from './DevicePickerPage';
import { ContactListPage } from './ContactListPage';
import { MessageListPage } from './MessageListPage';
import { ContactDetailPage } from './ContactDetailPage';
import { MessageDetailPage } from './MessageDetailPage';

/**
 * Home / Dashboard (3.3.4 screen 1).
 *
 * Shows the live Bluetooth status, sync action buttons and last-sync times.
 * All actions delegate to the BridgeService singleton; this struct only reads
 * reactive AppStorage state.
 */
@Entry
@Component
struct Index {
  @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
  @StorageProp(StoreKeys.CONN_STATE) connState: string = ConnState.DISCONNECTED;
  @StorageProp(StoreKeys.STATUS_TEXT) statusText: string = 'Not connected';
  @StorageProp(StoreKeys.CONTACT_SYNC) contactSync: string = SyncState.IDLE;
  @StorageProp(StoreKeys.MESSAGE_SYNC) messageSync: string = SyncState.IDLE;
  @StorageProp(StoreKeys.LAST_CONTACT_SYNC) lastContactSync: string = 'never';
  @StorageProp(StoreKeys.LAST_MESSAGE_SYNC) lastMessageSync: string = 'never';

  private bridge: BridgeService = BridgeService.get();

  aboutToAppear(): void {
    this.bridge.initStore();
  }

  @Builder
  pageMap(name: string, param: unknown) {
    if (name === 'DevicePickerPage') {
      DevicePickerPage()
    } else if (name === 'ContactListPage') {
      ContactListPage()
    } else if (name === 'MessageListPage') {
      MessageListPage()
    } else if (name === 'ContactDetailPage') {
      ContactDetailPage()
    } else if (name === 'MessageDetailPage') {
      MessageDetailPage()
    }
  }

  private statusColor(): string {
    if (this.connState === ConnState.CONNECTED) {
      return AppTheme.GREEN;
    }
    if (this.connState === ConnState.CONNECTING) {
      return AppTheme.YELLOW;
    }
    if (this.connState === ConnState.ERROR) {
      return AppTheme.RED;
    }
    return AppTheme.TEXT_DIM;
  }

  private async onSyncContacts(): Promise<void> {
    await this.bridge.syncContacts();
    promptAction.openToast({ message: 'Contacts synced' });
  }

  private async onSyncMessages(): Promise<void> {
    await this.bridge.syncMessages();
    promptAction.openToast({ message: 'Messages synced' });
  }

  @Builder
  ActionButton(label: string, sub: string, accent: string, loading: boolean, action: () => void) {
    Button() {
      Row({ space: 8 }) {
        if (loading) {
          LoadingProgress().width(20).height(20).color(AppTheme.TEXT)
        }
        Column() {
          Text(label)
            .fontSize(AppTheme.BODY_FS)
            .fontColor(AppTheme.TEXT)
            .fontWeight(FontWeight.Medium)
          Text(sub)
            .fontSize(AppTheme.SMALL_FS)
            .fontColor(AppTheme.TEXT_DIM)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 14, right: 14 })
    }
    .type(ButtonType.Capsule)
    .height(52)
    .width('100%')
    .backgroundColor(accent)
    .onClick(action)
  }

  build() {
    Navigation(this.pageStack) {
      Column() {
        Scroll() {
          Column({ space: AppTheme.GAP }) {
            // Header with live status dot
            Row({ space: 8 }) {
              Circle({ width: 12, height: 12 }).fill(this.statusColor())
              Text('BT Bridge')
                .fontSize(AppTheme.TITLE_FS)
                .fontColor(AppTheme.TEXT)
                .fontWeight(FontWeight.Bold)
            }
            .margin({ top: 6, bottom: 2 })

            Text(this.statusText)
              .fontSize(AppTheme.SMALL_FS)
              .fontColor(AppTheme.TEXT_DIM)
              .maxLines(2)
              .textAlign(TextAlign.Center)
              .width('100%')

            // Connect / choose device
            this.ActionButton(
              this.connState === ConnState.CONNECTED ? 'Connected' : 'Connect Phone',
              this.connState === ConnState.CONNECTED ? 'Tap to change device' : 'Select a paired phone',
              AppTheme.CARD_ACCENT,
              this.connState === ConnState.CONNECTING,
              () => this.pageStack.pushPathByName('DevicePickerPage', null)
            )

            // Sync contacts
            this.ActionButton(
              'Sync Contacts',
              `Last: ${this.lastContactSync}`,
              AppTheme.CARD,
              this.contactSync === SyncState.LOADING,
              () => { this.onSyncContacts(); }
            )

            // Sync messages
            this.ActionButton(
              'Sync Messages',
              `Last: ${this.lastMessageSync}`,
              AppTheme.CARD,
              this.messageSync === SyncState.LOADING,
              () => { this.onSyncMessages(); }
            )

            Divider().color('#333333').margin({ top: 2, bottom: 2 })

            // View lists
            this.ActionButton('View Contacts', 'Open phonebook', AppTheme.CARD, false,
              () => this.pageStack.pushPathByName('ContactListPage', null))

            this.ActionButton('View Messages', 'Open inbox', AppTheme.CARD, false,
              () => this.pageStack.pushPathByName('MessageListPage', null))

            Blank().height(10)
          }
          .width('100%')
          .padding({ left: AppTheme.SCREEN_PAD, right: AppTheme.SCREEN_PAD })
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppTheme.BG)
    }
    .navDestination(this.pageMap)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.BG)
  }
}
