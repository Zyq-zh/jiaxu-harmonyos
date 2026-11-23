import { HomeFlowApi, HomeFlowTask } from '../../api/HomeFlowApi';
import { HomeFlowV03, V03MemberScore, V03Statistics } from '../../api/HomeFlowV03';

@Component
export struct StatisticsPage {
  pageStack: NavPathStack = new NavPathStack();
  @State private period: number = 0;
  @State private taskList: HomeFlowTask[] = [];
  @State private loading: boolean = false;
  @State private hint: string = '';
  @State private statisticsData: V03Statistics | null = null;
  @StorageLink('homeflowTaskRevision') @Watch('onTaskChanged') private sharedTaskRevision: number = 0;

  aboutToAppear(): void { this.load(); }

  private onTaskChanged(): void { this.load(); }

  private dateKey(date: Date): string {
    return date.getFullYear().toString() + '-' +
      (date.getMonth() + 1).toString().padStart(2, '0') + '-' +
      date.getDate().toString().padStart(2, '0');
  }

  private startDate(): Date {
    const today: Date = new Date();
    if (this.period === 0) {
      return new Date(today.getFullYear(), today.getMonth(),
        today.getDate() - (today.getDay() + 6) % 7);
    }
    return new Date(today.getFullYear(), today.getMonth(), 1);
  }

  private endDate(): Date {
    const today: Date = new Date();
    if (this.period === 0) {
      const start: Date = this.startDate();
      return new Date(start.getFullYear(), start.getMonth(), start.getDate() + 6);
    }
    return new Date(today.getFullYear(), today.getMonth() + 1, 0);
  }

  private async load(): Promise<void> {
    if (this.loading) { return; }
    this.loading = true;
    try {
      this.taskList = await HomeFlowApi.tasks(this.dateKey(this.startDate()), this.dateKey(this.endDate()));
      this.statisticsData = await HomeFlowV03.statistics(this.dateKey(this.startDate()), this.dateKey(this.endDate()));
      this.hint = '';
    } catch (error) {
      this.hint = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private switchPeriod(value: number): void {
    if (this.period === value) { return; }
    this.period = value;
    this.load();
  }

  private count(status: string): number {
    return this.taskList.filter((task: HomeFlowTask): boolean => task.status === status).length;
  }

  @Builder
  statusRow(label: string, value: number, color: string) {
    Row({ space: 10 }) {
      Text(label).fontSize(14).fontColor('#30363A').width(70)
      Column() {}.height(14).width(Math.max(8, value * 14))
        .backgroundColor(color).borderRadius(7)
      Text(value.toString()).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#34745D')
    }.width('100%').height(35)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Row({ space: 13 }) {
            Image($r('app.media.hf_space_back')).width(38).height(38)
              .onClick(() => this.pageStack.pop())
            Text('公平统计').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
          }.width('100%').margin({ top: 12, bottom: 10 })
          Text('根据当前任务数据展示完成情况')
            .fontSize(13).fontColor('#798780').width('100%')
          Row({ space: 9 }) {
            Button('本周').layoutWeight(1).height(38)
              .fontColor(this.period === 0 ? '#FFFFFF' : '#34745D')
              .backgroundColor(this.period === 0 ? '#4C9C7C' : '#E7F3EA')
              .onClick(() => this.switchPeriod(0))
            Button('本月').layoutWeight(1).height(38)
              .fontColor(this.period === 1 ? '#FFFFFF' : '#34745D')
              .backgroundColor(this.period === 1 ? '#4C9C7C' : '#E7F3EA')
              .onClick(() => this.switchPeriod(1))
          }.width('100%').margin({ top: 22, bottom: 14 })
          Text(this.dateKey(this.startDate()) + ' 至 ' + this.dateKey(this.endDate()))
            .fontSize(13).fontColor('#798780').width('100%')
          Column({ space: 14 }) {
            Text('任务概览').fontSize(20).fontWeight(FontWeight.Bold)
              .fontColor('#30363A').width('100%')
            Text('共 ' + this.taskList.length.toString() + ' 项任务')
              .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#34745D').width('100%')
            this.statusRow('已完成', this.count('completed'), '#4C9C7C')
            this.statusRow('待完成', this.count('todo'), '#A5C9A7')
            this.statusRow('待分配', this.count('unassigned'), '#D5BD8C')
            this.statusRow('已取消', this.count('cancelled'), '#E3B0A1')
          }.padding(19).width('100%').backgroundColor('#FFFFFF').borderRadius(17)
            .border({ width: 1, color: '#DCE8DF' }).margin({ top: 16 })
          if (this.loading) {
            Text('正在读取任务…').fontSize(13).fontColor('#798780').margin({ top: 13 })
          }
          if (this.hint.length > 0) {
            Text(this.hint).fontSize(13).fontColor('#BF715D').margin({ top: 13 })
            Button('重试').backgroundColor('#4C9C7C').onClick(() => this.load())
          }
          Column({ space: 10 }) {
            Image($r('app.media.hf_feature_consensus')).width(68).height(68)
            Text('成员贡献分').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#30363A')
            if (this.statisticsData !== null) {
              Text('完成 ' + this.statisticsData.completedCount.toString() + ' / ' +
                this.statisticsData.plannedCount.toString() + ' 项')
                .fontSize(13).fontColor('#798780')
              ForEach(this.statisticsData.members, (member: V03MemberScore) => {
                Row() {
                  Text(member.nickname).layoutWeight(1).fontSize(15).fontColor('#30363A')
                  Text(member.score.toFixed(1) + ' 分').fontSize(15).fontColor('#34745D')
                }.width('100%').padding(9)
              }, (member: V03MemberScore): string => member.userId)
            }
          }.padding(25).width('100%').backgroundColor('#E7F3EA').borderRadius(16)
            .margin({ top: 18 })
          Button('评分说明').width('100%').height(43)
            .fontColor('#34745D').backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#DCE8DF' }).margin({ top: 19 })
            .onClick(() => this.getUIContext().showAlertDialog({
              title: '评分说明',
              message: '完成审批后计分：预计分钟 ÷ 30 × 难度系数（简单 1、中等 1.3、较难 1.6），保留一位小数。单人空间本人完成会标记未经室友审核。',
              confirm: { value: '知道了', action: () => {} }
            }))
        }.padding({ left: 24, right: 24, top: 5, bottom: 30 }).width('100%')
      }.width('100%').height('100%')
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
