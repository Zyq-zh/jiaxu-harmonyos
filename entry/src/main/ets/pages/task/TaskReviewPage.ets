import { HomeFlowApi, HomeFlowTask, HomeFlowTaskDetailData } from '../../api/HomeFlowApi';

@Component
export struct TaskReviewPage {
  pageStack: NavPathStack = new NavPathStack();
  taskId: string = '';
  @State private task: HomeFlowTask | null = null;
  @State private hint: string = '';

  aboutToAppear(): void { this.load(); }

  private async load(): Promise<void> {
    try {
      const detail: HomeFlowTaskDetailData = await HomeFlowApi.taskDetail(this.taskId);
      this.task = detail.task;
      this.hint = '';
    } catch (error) {
      this.hint = (error as Error).message;
    }
  }

  private vote(agree: boolean): void {
    this.getUIContext().showAlertDialog({
      title: agree ? '同意完成' : '需要补充',
      message: '照片审批接口尚未提供，本次选择不会提交。需在服务端核验本人身份、任务状态和其他成员过半票数。',
      confirm: { value: '知道了', action: () => {} }
    });
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column({ space: 13 }) {
            Row({ space: 12 }) {
              Image($r('app.media.hf_space_back')).width(38).height(38)
                .onClick(() => this.pageStack.pop())
              Text('完成照片审批').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
            }.width('100%').margin({ top: 12 })
            Text(this.task === null ? '正在读取任务…' : this.task.title)
              .fontSize(16).fontColor('#34745D').width('100%')
            Text('查看开工前与完工后的照片，再决定是否同意完成。')
              .fontSize(13).fontColor('#798780').width('100%')
            Column({ space: 11 }) {
              Text('开工前照片').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#30363A')
                .width('100%')
              Text('照片数据待接入').fontSize(14).fontColor('#798780')
                .width('100%').textAlign(TextAlign.Center).padding(54)
                .backgroundColor('#F0F5EC').borderRadius(12)
              Text('完工后照片').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#30363A')
                .width('100%')
              Text('照片数据待接入').fontSize(14).fontColor('#798780')
                .width('100%').textAlign(TextAlign.Center).padding(54)
                .backgroundColor('#F0F5EC').borderRadius(12)
            }.padding(16).width('100%').backgroundColor('#FFFFFF').borderRadius(16)
              .border({ width: 1, color: '#DCE8DF' })
            if (this.hint.length > 0) {
              Text(this.hint).fontSize(13).fontColor('#BF715D').width('100%')
            }
            Text('本人不可审核自己提交的照片；其他成员过半同意才会计入成果。')
              .fontSize(12).fontColor('#798780').width('100%')
          }.padding({ left: 24, right: 24, top: 5, bottom: 20 }).width('100%')
        }.layoutWeight(1).width('100%')
        Row({ space: 10 }) {
          Button('需要补充').layoutWeight(1).height(46)
            .fontColor('#BF715D').backgroundColor('#FFF0EA')
            .onClick(() => this.vote(false))
          Button('同意完成').layoutWeight(1).height(46)
            .backgroundColor('#4C9C7C').onClick(() => this.vote(true))
        }.padding({ left: 24, right: 24, top: 9, bottom: 9 }).width('100%')
      }.width('100%').height('100%')
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
