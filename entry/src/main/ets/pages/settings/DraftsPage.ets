import { HomeFlowClipboard } from '../../utils/HomeFlowClipboard';
import { HomeFlowV03, V03Draft } from '../../api/HomeFlowV03';

@Component
export struct DraftsPage {
  pageStack: NavPathStack = new NavPathStack();
  @State private drafts: V03Draft[] = [];
  @State private selectedId: string = '';
  @State private editTitle: string = '';
  @State private editContent: string = '';
  @State private editTone: number = 0;
  @State private showEdit: boolean = false;
  @State private hint: string = '';
  @State private selectedVersion: number = 0;

  aboutToAppear(): void { this.refresh(); }

  private async refresh(): Promise<void> {
    try { this.drafts = await HomeFlowV03.drafts(); this.hint = ''; }
    catch (error) { this.hint = (error as Error).message; }
  }

  private toneLabel(tone: string): string {
    if (tone === 'friendly') { return '轻松友好'; }
    if (tone === 'direct') { return '清晰直接'; }
    return '温柔委婉';
  }

  private open(draft: V03Draft): void {
    this.selectedId = draft.id;
    this.selectedVersion = draft.version;
    this.editTitle = draft.title;
    this.editContent = draft.body;
    this.editTone = draft.tone === 'friendly' ? 1 : (draft.tone === 'direct' ? 2 : 0);
    this.hint = '';
    this.showEdit = true;
  }

  private async save(): Promise<void> {
    try {
      await HomeFlowV03.updateDraft(this.selectedId, this.selectedVersion,
        this.editTitle.trim(), this.editContent.trim(),
        this.editTone === 1 ? 'friendly' : (this.editTone === 2 ? 'direct' : 'gentle'));
      await this.refresh();
      this.showEdit = false;
    } catch (error) {
      this.hint = (error as Error).message;
    }
  }

  private remove(): void {
    this.getUIContext().showAlertDialog({
      title: '删除这条草稿？', message: '删除后本次会话中无法找回。',
      primaryButton: { value: '保留', action: () => {} },
      secondaryButton: { value: '删除', action: () => this.confirmRemove() }
    });
  }

  private async confirmRemove(): Promise<void> {
    try {
      await HomeFlowV03.deleteDraft(this.selectedId, this.selectedVersion);
      await this.refresh();
      this.showEdit = false;
    } catch (error) { this.hint = (error as Error).message; }
  }

  private async copy(): Promise<void> {
    try {
      await HomeFlowClipboard.copy(this.editContent);
      this.getUIContext().showAlertDialog({
        message: '草稿已复制', confirm: { value: '知道了', action: () => {} }
      });
    } catch (error) {
      this.hint = '复制失败，请重试';
    }
  }

  @Builder
  editSheet() {
    Column({ space: 12 }) {
      Row() {
        Text('编辑私有草稿').fontSize(21).fontWeight(FontWeight.Bold)
          .fontColor('#30363A').layoutWeight(1)
        Text('×').fontSize(26).fontColor('#30363A').onClick(() => this.showEdit = false)
      }.width('100%')
      TextInput({ text: this.editTitle, placeholder: '草稿标题' })
        .maxLength(50).height(45).width('100%').backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#DCE8DF' })
        .onChange((value: string) => this.editTitle = value)
      TextArea({ text: this.editContent, placeholder: '想说的话' })
        .maxLength(500).height(135).width('100%').backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#DCE8DF' })
        .onChange((value: string) => this.editContent = value)
      if (this.hint.length > 0) {
        Text(this.hint).fontSize(12).fontColor('#BF715D').width('100%')
      }
      Row({ space: 8 }) {
        Button('删除').layoutWeight(1).height(43)
          .fontColor('#BF715D').backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#F0D9D0' }).onClick(() => this.remove())
        Button('复制').layoutWeight(1).height(43)
          .fontColor('#34745D').backgroundColor('#E7F3EA').onClick(() => this.copy())
        Button('保存').layoutWeight(1).height(43)
          .backgroundColor('#4C9C7C').onClick(() => this.save())
      }.width('100%')
    }.padding(22).width('100%').backgroundColor('#FFF9F2')
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            Row({ space: 12 }) {
              Image($r('app.media.hf_space_back')).width(38).height(38)
                .onClick(() => this.pageStack.pop())
              Column({ space: 2 }) {
                Text('私有沟通草稿').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
                Text('只对当前账号可见').fontSize(13).fontColor('#798780')
              }.alignItems(HorizontalAlign.Start)
            }.width('100%').margin({ top: 12, bottom: 24 })
            Text(this.drafts.length.toString() + ' 条草稿')
              .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#34745D')
              .padding({ left: 17, right: 17, top: 7, bottom: 7 })
              .backgroundColor('#E7F3EA').borderRadius(13)
              .width('100%')
            ForEach(this.drafts, (draft: V03Draft) => {
              Column({ space: 10 }) {
                Row({ space: 12 }) {
                  Image($r('app.media.hf_tab_communication')).width(42).height(42)
                  Column({ space: 3 }) {
                    Text(draft.title).fontSize(17).fontWeight(FontWeight.Bold)
                      .fontColor('#30363A').maxLines(1)
                    Text(draft.updatedAt.substring(0, 10) + ' 保存 · ' + this.toneLabel(draft.tone))
                      .fontSize(12).fontColor('#798780')
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                  Text('›').fontSize(22).fontColor('#34745D')
                }.width('100%')
                Divider().strokeWidth(1).color('#E2EAE3')
                Text(draft.body).fontSize(14).fontColor('#30363A')
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
              }.padding(16).width('100%').backgroundColor('#FFFFFF').borderRadius(16)
                .border({ width: 1, color: '#DCE8DF' }).margin({ top: 14 })
                .onClick(() => this.open(draft))
            }, (draft: V03Draft): string => draft.id)
            if (this.drafts.length === 0) {
              Column({ space: 11 }) {
                Image($r('app.media.hf_tab_communication')).width(79).height(79)
                Text('还没有草稿').fontSize(19).fontWeight(FontWeight.Bold).fontColor('#30363A')
                Text('在沟通页整理并保存表达，稍后可以回来修改。')
                  .fontSize(13).fontColor('#798780').textAlign(TextAlign.Center)
              }.padding(27).width('100%').backgroundColor('#FFFFFF').borderRadius(16)
                .margin({ top: 17 })
            }
            Text('草稿保存在当前账号，不会自动发给室友。')
              .fontSize(12).fontColor('#34745D').padding(14).width('100%')
              .backgroundColor('#EFF6EE').borderRadius(12).margin({ top: 29 })
          }.padding({ left: 24, right: 24, top: 5, bottom: 20 }).width('100%')
        }.layoutWeight(1).width('100%')
          .bindSheet($$this.showEdit, this.editSheet, {
            height: SheetSize.MEDIUM, dragBar: false, backgroundColor: '#FFF9F2'
          })
        Button('返回个人设置').width('100%').height(46)
          .backgroundColor('#4C9C7C').onClick(() => this.pageStack.pop())
          .margin({ left: 24, right: 24, top: 9, bottom: 9 })
      }.width('100%').height('100%')
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
