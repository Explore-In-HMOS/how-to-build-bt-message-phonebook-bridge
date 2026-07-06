import { abilityAccessCtrl, AbilityConstant, ConfigurationConstant, Permissions, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

const BT_PERMISSIONS: Permissions[] = ['ohos.permission.ACCESS_BLUETOOTH'];

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    this.requestBluetoothPermission();
  }

  // Ask the user to grant Bluetooth access up front so the bridge can connect.
  private requestBluetoothPermission(): void {
    try {
      const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      atManager.requestPermissionsFromUser(this.context, BT_PERMISSIONS)
        .then((result) => {
          hilog.info(DOMAIN, 'testTag', 'Bluetooth permission result: %{public}s',
            JSON.stringify(result.authResults));
        })
        .catch((err: Object) => {
          hilog.error(DOMAIN, 'testTag', 'requestPermissions failed: %{public}s', JSON.stringify(err));
        });
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'requestPermissions threw: %{public}s', JSON.stringify(err));
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
};