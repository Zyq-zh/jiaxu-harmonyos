import { HomeFlowApi, HomeFlowTask, HomeFlowTaskDetailData } from '../../api/HomeFlowApi';
import { HomeFlowV03 } from '../../api/HomeFlowV03';

@Component
export struct SwapRequestPage {
  pageStack: NavPathStack = new NavPathStack();
  taskId: string = '';
  @State private source: HomeFlowTask | null = null;
  @State private options: HomeFlowTask[] = [];
  @State private targetId: string = '';
  @State private reason: string = '';
  @State private hint: string = '';

  aboutToAppear(): void { this.load(); }

  private async load(): Promise<void> {
    if (this.taskId.length === 0) { return; }
    try {
      const detail: HomeFlowTaskDetailData = await HomeFlowApi.taskDetail(this.taskId);
      this.source = detail.task;
      this.options = await HomeFlowV03.swapCandidates(this.taskId);
      this.hint = '';
    } catch (error) {
      this.hint = (error as Error).message;
    }
  }

  private async submit(): Promise<void> {
    if (this.targetId.length === 0) { this.hint = '请选择要交换的任务'; return; }
    if (this.source === null) { return; }
    const target: HomeFlowTask | undefined = this.options.find((task: HomeFlowTask): boolean => task.id === this.targetId);
    if (target === undefined) { this.hint = '候选任务已变化，请刷新'; return; }
    try {
      await HomeFlowV03.swap(this.source.id, target.id, this.source.version, target.version, this.reason.trim());
      this.getUIContext().showAlertDialog({
        title: '申请已发送', message: '对方同意后，任务责任人才会变更。',
        confirm: { value: '知道了', action: () => this.pageStack.pop() }
      });
    } catch (error) { this.hint = (error as Error).message; }
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            Row({ space: 12 }) {
              Image($r('app.media.hf_space_back')).width(38).height(38)
                .onClick(() => this.pageStack.pop())
              Text('申请换班').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
            }.width('100%').margin({ top: 12, bottom: 10 })
            Text('和室友商量，把两项任务交换一下')
              .fontSize(13).fontColor('#798780').width('100%')
            Text('我的任务').fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor('#30363A').width('100%').margin({ top: 23, bottom: 10 })
            Text(this.source === null ? '正在读取任务…' :
              this.source.title + ' · ' + this.source.executionDate)
              .fontSize(16).fontColor('#30363A').padding(17)
              .width('100%').backgroundColor('#E7F3EA').borderRadius(14)
            Text('选择要交换的任务').fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor('#30363A').width('100%').margin({ top: 23, bottom: 10 })
            ForEach(this.options, (task: HomeFlowTask) => {
              Row({ space: 9 }) {
                Image($r('app.media.hf_tab_schedule')).width(39).height(39)
                Column({ space: 4 }) {
                  Text(task.title).fontSize(15).fontWeight(FontWeight.Bold).fontColor('#30363A')
                  Text(task.executionDate).fontSize(12).fontColor('#798780')
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Text(this.targetId === task.id ? '✓' : '○')
                  .fontSize(19).fontColor('#34745D')
              }.padding(14).width('100%').backgroundColor(this.targetId === task.id ?
                '#E7F3EA' : '#FFFFFF').borderRadius(13)
                .border({ width: 1, color: '#DCE8DF' }).margin({ bottom: 8 })
                .onClick(() => { this.targetId = task.id; this.hint = ''; })
            }, (task: HomeFlowTask): string => task.id)
            if (this.options.length === 0) {
              Text('本周暂无可选择的任务')
                .fontSize(14).fontColor('#798780').padding(17)
                .width('100%').backgroundColor('#FFFFFF').borderRadius(13)
            }
            Text('换班原因').fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor('#30363A').width('100%').margin({ top: 22, bottom: 10 })
            TextArea({ placeholder: '简单说明一下，方便室友判断', text: this.reason })
              .maxLength(200).height(105).width('100%').backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#DCE8DF' }).borderRadius(13)
              .onChange((value: string) => { this.reason = value; this.hint = ''; })
            if (this.hint.length > 0) {
              Text(this.hint).fontSize(12).fontColor('#BF715D').margin({ top: 9 })
            }
            Text('申请需要对方同意；提交前两项任务不会改变。')
              .fontSize(12).fontColor('#798780').width('100%').margin({ top: 16 })
          }.padding({ left: 24, right: 24, top: 5, bottom: 20 }).width('100%')
        }.layoutWeight(1).width('100%')
        Button('提交换班申请').width('100%').height(48)
          .backgroundColor('#4C9C7C').onClick(() => this.submit())
          .margin({ left: 24, right: 24, top: 9, bottom: 9 })
      }.width('100%').height('100%')
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
