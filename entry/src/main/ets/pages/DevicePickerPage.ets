import { promptAction } from '@kit.ArkUI';
import { BridgeService } from '../service/BridgeService';
import { PairedDevice } from '../model/BridgeTypes';
import { DemoData } from '../service/DemoData';
import { AppTheme } from '../common/AppTheme';

/**
 * Device picker (3.3.1 step 3 — "User selects the target phone").
 * Lists paired phones; tapping one opens an SPP connection via BridgeService.
 */
@Component
export struct DevicePickerPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @State devices: PairedDevice[] = [];
  @State connectingId: string = '';

  private bridge: BridgeService = BridgeService.get();

  aboutToAppear(): void {
    const paired: PairedDevice[] = this.bridge.listPairedDevices();
    // Offline-first: if nothing is paired (e.g. emulator), show demo phones so
    // the flow can still be exercised end-to-end.
    this.devices = paired.length > 0 ? paired : DemoData.pairedDevices();
  }

  private async onSelect(device: PairedDevice): Promise<void> {
    this.connectingId = device.deviceId;
    const ok: boolean = await this.bridge.connect(device);
    this.connectingId = '';
    if (ok) {
      promptAction.openToast({ message: 'Connected' });
      this.pageStack.pop();
    } else {
      promptAction.openToast({ message: 'Connection failed — try again' });
    }
  }

  build() {
    NavDestination() {
      Column() {
        Text('Choose Phone')
          .fontSize(AppTheme.TITLE_FS)
          .fontColor(AppTheme.TEXT)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 8, bottom: 6 })

        List({ space: AppTheme.GAP }) {
          ForEach(this.devices, (item: PairedDevice) => {
            ListItem() {
              Row({ space: 10 }) {
                Image($r('app.media.startIcon')).width(28).height(28).borderRadius(14)
                Column() {
                  Text(item.name)
                    .fontSize(AppTheme.BODY_FS)
                    .fontColor(AppTheme.TEXT)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.deviceId)
                    .fontSize(AppTheme.SMALL_FS)
                    .fontColor(AppTheme.TEXT_DIM)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                if (this.connectingId === item.deviceId) {
                  LoadingProgress().width(20).height(20).color(AppTheme.PRIMARY)
                }
              }
              .width('100%')
              .padding(12)
            }
            .backgroundColor(AppTheme.CARD)
            .borderRadius(AppTheme.RADIUS)
            .onClick(() => { this.onSelect(item); })
          }, (item: PairedDevice) => item.deviceId)
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding({ left: AppTheme.SCREEN_PAD, right: AppTheme.SCREEN_PAD })
    }
    .hideTitleBar(true)
    .backgroundColor(AppTheme.BG)
  }
}
