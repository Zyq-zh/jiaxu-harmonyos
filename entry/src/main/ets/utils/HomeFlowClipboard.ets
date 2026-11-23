import { pasteboard } from '@kit.BasicServicesKit';

export class HomeFlowClipboard {
  static async copy(content: string): Promise<void> {
    const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content);
    const board: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    await board.setData(data);
  }
}
