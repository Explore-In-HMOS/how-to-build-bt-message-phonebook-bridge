import { hilog } from '@kit.PerformanceAnalysisKit';

/** Thin wrapper around hilog so every module logs under a shared domain/tag. */
const DOMAIN: number = 0x1F00;
const TAG: string = 'BtBridge';

export class Logger {
  static info(msg: string): void {
    hilog.info(DOMAIN, TAG, '%{public}s', msg);
  }

  static warn(msg: string): void {
    hilog.warn(DOMAIN, TAG, '%{public}s', msg);
  }

  static error(msg: string): void {
    hilog.error(DOMAIN, TAG, '%{public}s', msg);
  }
}
