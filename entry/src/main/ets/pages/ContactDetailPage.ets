import { Contact } from '../model/BridgeTypes';
import { StoreKeys } from '../common/StoreKeys';
import { AppTheme } from '../common/AppTheme';

/**
 * Contact detail (3.3.4 screen 4). Reads the selected contact from AppStorage
 * and shows the full name, every number and any emails.
 */
@Component
export struct ContactDetailPage {
  @StorageProp(StoreKeys.SELECTED_CONTACT) contact: Contact =
    { id: '', name: '—', phoneNumbers: [], emails: [] };

  @Builder
  Field(label: string, value: string) {
    Column({ space: 2 }) {
      Text(label).fontSize(AppTheme.SMALL_FS).fontColor(AppTheme.TEXT_DIM)
      Text(value)
        .fontSize(AppTheme.BODY_FS)
        .fontColor(AppTheme.TEXT)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .backgroundColor(AppTheme.CARD)
    .borderRadius(AppTheme.RADIUS)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: AppTheme.GAP }) {
          // Avatar + name header
          Stack() {
            Circle({ width: 56, height: 56 }).fill(AppTheme.CARD_ACCENT)
            Text(this.contact.name.length > 0 ? this.contact.name.substring(0, 1).toUpperCase() : '?')
              .fontSize(24)
              .fontColor(AppTheme.TEXT)
              .fontWeight(FontWeight.Bold)
          }
          .margin({ top: 10 })

          Text(this.contact.name)
            .fontSize(AppTheme.TITLE_FS)
            .fontColor(AppTheme.TEXT)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .width('100%')

          ForEach(this.contact.phoneNumbers, (num: string) => {
            this.Field(`Phone ${this.contact.phoneNumbers.indexOf(num) + 1}`, num)
          }, (num: string) => num)

          ForEach(this.contact.emails, (mail: string) => {
            this.Field(`Email ${this.contact.emails.indexOf(mail) + 1}`, mail)
          }, (mail: string) => mail)

          if (this.contact.phoneNumbers.length === 0 && this.contact.emails.length === 0) {
            Text('No additional details')
              .fontSize(AppTheme.SMALL_FS)
              .fontColor(AppTheme.TEXT_DIM)
              .margin({ top: 8 })
          }

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
