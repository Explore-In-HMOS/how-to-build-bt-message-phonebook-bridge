/** Small date helpers tuned for tiny watch screens (short, glanceable strings). */
export class TimeUtil {
  private static pad(n: number): string {
    return n < 10 ? `0${n}` : `${n}`;
  }

  /** "14:05" style clock for a given epoch-millis timestamp. */
  static clock(ts: number): string {
    const d: Date = new Date(ts);
    return `${TimeUtil.pad(d.getHours())}:${TimeUtil.pad(d.getMinutes())}`;
  }

  /** Relative, compact age: "now", "5m", "3h", "2d". */
  static ago(ts: number): string {
    const diff: number = new Date().getTime() - ts;
    const min: number = Math.floor(diff / 60000);
    if (min < 1) {
      return 'now';
    }
    if (min < 60) {
      return `${min}m`;
    }
    const hr: number = Math.floor(min / 60);
    if (hr < 24) {
      return `${hr}h`;
    }
    return Math.floor(hr / 24) + 'd';
  }

  /** Full timestamp for detail views: "2026-06-25 14:05". */
  static full(ts: number): string {
    const d: Date = new Date(ts);
    return `${d.getFullYear()}-${TimeUtil.pad(d.getMonth() + 1)}-${TimeUtil.pad(d.getDate())} ${TimeUtil.pad(d.getHours())}:${TimeUtil.pad(d.getMinutes())}`;
  }
}
