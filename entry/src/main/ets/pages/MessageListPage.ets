import { BridgeService } from '../service/BridgeService';
import { Message, SyncState } from '../model/BridgeTypes';
import { StoreKeys } from '../common/StoreKeys';
import { AppTheme } from '../common/AppTheme';
import { TimeUtil } from '../common/TimeUtil';

/**
 * Message list (3.3.4 screen 3). Newest first (sorted in MapManager). Unread
 * messages are highlighted with an accent card and a dot.
 */
@Component
export struct MessageListPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink(StoreKeys.MESSAGES) messages: Message[] = [];
  @StorageProp(StoreKeys.MESSAGE_SYNC) syncState: string = SyncState.IDLE;

  private bridge: BridgeService = BridgeService.get();

  aboutToAppear(): void {
    if (this.messages.length === 0) {
      this.bridge.syncMessages();
    }
  }

  private openMessage(m: Message): void {
    AppStorage.setOrCreate<Message>(StoreKeys.SELECTED_MESSAGE, m);
    this.pageStack.pushPathByName('MessageDetailPage', null);
  }

  build() {
    NavDestination() {
      Column() {
        Row({ space: 6 }) {
          Text('Messages')
            .fontSize(AppTheme.TITLE_FS)
            .fontColor(AppTheme.TEXT)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          Text(`${this.messages.length}`)
            .fontSize(AppTheme.SMALL_FS)
            .fontColor(AppTheme.TEXT_DIM)
        }
        .width('100%')
        .margin({ top: 8, bottom: 6 })

        if (this.syncState === SyncState.LOADING && this.messages.length === 0) {
          Column({ space: 10 }) {
            LoadingProgress().width(36).height(36).color(AppTheme.PRIMARY)
            Text('Syncing…').fontSize(AppTheme.SMALL_FS).fontColor(AppTheme.TEXT_DIM)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.messages.length === 0) {
          Text('No messages yet')
            .fontSize(AppTheme.BODY_FS)
            .fontColor(AppTheme.TEXT_DIM)
            .layoutWeight(1)
        } else {
          List({ space: AppTheme.GAP }) {
            ForEach(this.messages, (item: Message) => {
              ListItem() {
                Column({ space: 3 }) {
                  Row({ space: 6 }) {
                    if (!item.read) {
                      Circle({ width: 8, height: 8 }).fill(AppTheme.PRIMARY)
                    }
                    Text(item.sender)
                      .fontSize(AppTheme.BODY_FS)
                      .fontColor(AppTheme.TEXT)
                      .fontWeight(item.read ? FontWeight.Normal : FontWeight.Bold)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    Text(TimeUtil.ago(item.timestamp))
                      .fontSize(AppTheme.SMALL_FS)
                      .fontColor(AppTheme.TEXT_DIM)
                  }
                  .width('100%')

                  Text(item.content)
                    .fontSize(AppTheme.SMALL_FS)
                    .fontColor(AppTheme.TEXT_DIM)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                }
                .alignItems(HorizontalAlign.Start)
                .width('100%')
                .padding(10)
              }
              .backgroundColor(item.read ? AppTheme.CARD : AppTheme.CARD_ACCENT)
              .borderRadius(AppTheme.RADIUS)
              .onClick(() => this.openMessage(item))
            }, (item: Message) => item.id)
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
