import { HomeFlowClipboard } from '../../utils/HomeFlowClipboard';
import { HomeFlowV03, V03Suggestion, V03Suggestions } from '../../api/HomeFlowV03';

@Component
export struct SuggestionsPage {
  pageStack: NavPathStack = new NavPathStack();
  concernText: string = '';
  initialTone: number = 0;
  @State private selectedTone: number = 0;
  @State private suggestionText: string = '';
  @State private editing: boolean = false;
  @State private suggestionsList: V03Suggestion[] = [];
  @State private loading: boolean = false;
  @State private hint: string = '';

  aboutToAppear(): void { this.choose(this.initialTone); }

  private toneLabel(): string {
    if (this.selectedTone === 1) { return '轻松友好'; }
    if (this.selectedTone === 2) { return '清晰直接'; }
    return '温柔委婉';
  }

  private toneCode(): string {
    if (this.selectedTone === 1) { return 'friendly'; }
    if (this.selectedTone === 2) { return 'direct'; }
    return 'gentle';
  }

  private async choose(tone: number): Promise<void> {
    this.selectedTone = tone;
    this.editing = false;
    if (this.loading || this.concernText.trim().length === 0) { return; }
    this.loading = true;
    this.hint = '';
    try {
      const response: V03Suggestions = await HomeFlowV03.suggestions(this.concernText.trim(), this.toneCode());
      this.suggestionsList = response.suggestions;
      if (response.suggestions.length > 0) { this.suggestionText = response.suggestions[0].text; }
    } catch (error) { this.hint = (error as Error).message; }
    finally { this.loading = false; }
  }

  private async copy(): Promise<void> {
    try {
      await HomeFlowClipboard.copy(this.suggestionText);
      this.getUIContext().showAlertDialog({
        message: '内容已复制，可以按自己的习惯继续修改。',
        confirm: { value: '知道了', action: () => {} }
      });
    } catch (error) {
      this.getUIContext().showAlertDialog({
        message: '复制失败，请重试。', confirm: { value: '知道了', action: () => {} }
      });
    }
  }

  private async save(): Promise<void> {
    try {
      await HomeFlowV03.createDraft(this.concernText.substring(0, 18),
        this.suggestionText.substring(0, 500), this.concernText, this.toneCode());
      this.getUIContext().showAlertDialog({
        title: '私有草稿已保存',
        message: '可在个人设置中查看和修改，内容不会自动发给室友。',
        confirm: { value: '知道了', action: () => {} }
      });
    } catch (error) {
      this.getUIContext().showAlertDialog({
        message: (error as Error).message, confirm: { value: '知道了', action: () => {} }
      });
    }
  }

  @Builder
  toneButton(label: string, value: number) {
    Button(label).layoutWeight(1).height(39).fontSize(13)
      .fontColor(this.selectedTone === value ? '#FFFFFF' : '#34745D')
      .backgroundColor(this.selectedTone === value ? '#4C9C7C' : '#FFFFFF')
      .border({ width: 1, color: '#DCE8DF' }).borderRadius(10)
      .onClick(() => this.choose(value))
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Row({ space: 12 }) {
            Image($r('app.media.hf_space_back')).width(38).height(38)
              .onClick(() => this.pageStack.pop())
            Column({ space: 3 }) {
              Text('表达预览').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
              Text(this.toneLabel() + ' · AI 表达建议').fontSize(12).fontColor('#798780')
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Image($r('app.media.hf_communication_bubbles')).width(67).height(59)
          }.width('100%').margin({ top: 12, bottom: 20 })
          Column({ space: 6 }) {
            Text('先读一遍，再改成自己愿意说的话')
              .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#34745D').width('100%')
            Text('你主动生成后，输入会发给模型服务处理；建议不会自动发给室友。')
              .fontSize(12).fontColor('#798780').width('100%')
          }.padding(16).width('100%').backgroundColor('#E7F3EA').borderRadius(13)
          Text('选择表达语气').fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor('#30363A').width('100%').margin({ top: 23, bottom: 11 })
          Row({ space: 8 }) {
            this.toneButton('温柔委婉', 0)
            this.toneButton('轻松友好', 1)
            this.toneButton('清晰直接', 2)
          }.width('100%')
          if (this.loading) { Text('正在生成建议…').fontSize(13).fontColor('#798780') }
          if (this.hint.length > 0) {
            Text(this.hint).fontSize(13).fontColor('#BF715D').margin({ top: 10 })
            Button('重试生成').backgroundColor('#4C9C7C')
              .onClick(() => this.choose(this.selectedTone))
          }
          ForEach(this.suggestionsList, (suggestion: V03Suggestion) => {
            Text(suggestion.text).fontSize(13).fontColor('#34745D')
              .padding(12).width('100%').backgroundColor('#E7F3EA')
              .borderRadius(10).margin({ top: 8 })
              .onClick(() => { this.suggestionText = suggestion.text; this.editing = false; })
          }, (suggestion: V03Suggestion): string => suggestion.id)
          Column({ space: 12 }) {
            Row() {
              Text('当前内容 · 可编辑').fontSize(16).fontWeight(FontWeight.Bold)
                .fontColor('#30363A').layoutWeight(1)
              Text(this.editing ? '完成' : '编辑').fontSize(13).fontColor('#34745D')
                .onClick(() => this.editing = !this.editing)
            }.width('100%')
            Divider().strokeWidth(1).color('#E2EAE3')
            if (this.editing) {
              TextArea({ text: this.suggestionText }).height(180).maxLength(500)
                .fontSize(15).fontColor('#30363A').backgroundColor('#FFFFFF')
                .onChange((value: string) => this.suggestionText = value)
            } else {
              Text(this.suggestionText).fontSize(15).lineHeight(27)
                .fontColor('#30363A').width('100%')
            }
            Divider().strokeWidth(1).color('#E2EAE3')
            Text(this.suggestionText.length.toString() + ' 字')
              .fontSize(12).fontColor('#798780').width('100%').textAlign(TextAlign.End)
          }.padding(17).width('100%').backgroundColor('#FFFFFF').borderRadius(16)
            .border({ width: 1, color: '#DCE8DF' }).margin({ top: 17 })
          Row({ space: 10 }) {
            Button('重新生成').layoutWeight(1).height(43)
              .fontColor('#34745D').backgroundColor('#E7F3EA')
              .onClick(() => this.choose(this.selectedTone))
            Button('保存私有草稿').layoutWeight(1).height(43)
              .fontSize(12).fontColor('#34745D').backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#DCE8DF' }).onClick(() => this.save())
          }.width('100%').margin({ top: 21 })
          Button('复制这段话').width('100%').height(48)
            .fontSize(16).fontWeight(FontWeight.Bold).backgroundColor('#4C9C7C')
            .margin({ top: 20 }).onClick(() => this.copy())
          Text('当面交流时可按自己的习惯表达，不必逐字照念')
            .fontSize(12).fontColor('#798780').margin({ top: 12, bottom: 25 })
        }.padding({ left: 24, right: 24, top: 5 }).width('100%')
      }.width('100%').height('100%')
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
