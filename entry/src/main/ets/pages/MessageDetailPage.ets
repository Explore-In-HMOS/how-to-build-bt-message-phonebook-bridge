import { Message } from '../model/BridgeTypes';
import { StoreKeys } from '../common/StoreKeys';
import { AppTheme } from '../common/AppTheme';
import { TimeUtil } from '../common/TimeUtil';

/**
 * Message detail (3.3.4 screen 4). Shows the full message body with sender,
 * type and a full timestamp.
 */
@Component
export struct MessageDetailPage {
  @StorageProp(StoreKeys.SELECTED_MESSAGE) message: Message =
    { id: '', sender: '—', content: '', timestamp: 0, read: true, type: 'SMS' };

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: AppTheme.GAP }) {
          Row({ space: 6 }) {
            Text(this.message.sender)
              .fontSize(AppTheme.TITLE_FS)
              .fontColor(AppTheme.TEXT)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.message.type)
              .fontSize(AppTheme.SMALL_FS)
              .fontColor(AppTheme.PRIMARY)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor(AppTheme.CARD_ACCENT)
              .borderRadius(10)
          }
          .width('100%')
          .margin({ top: 10 })

          Text(TimeUtil.full(this.message.timestamp))
            .fontSize(AppTheme.SMALL_FS)
            .fontColor(AppTheme.TEXT_DIM)
            .width('100%')

          Column() {
            Text(this.message.content)
              .fontSize(AppTheme.BODY_FS)
              .fontColor(AppTheme.TEXT)
              .width('100%')
          }
          .width('100%')
          .padding(14)
          .backgroundColor(AppTheme.CARD)
          .borderRadius(AppTheme.RADIUS)

          Blank().height(12)
        }
        .width('100%')
        .padding({ left: AppTheme.SCREEN_PAD, right: AppTheme.SCREEN_PAD })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(AppTheme.BG)
  }
}
