import { HomeFlowApi, HomeFlowTask, HomeFlowTaskRouteParam } from '../../api/HomeFlowApi';
import { HomeFlowV03, V03Dashboard, V03Rule } from '../../api/HomeFlowV03';

@Component
export struct HomePage {
  pageStack: NavPathStack = new NavPathStack();
  onCreateTask: () => void = () => {};
  @Prop @Watch('onRevisionChanged') taskRevision: number = 0;
  @StorageLink('homeflowTaskRevision') @Watch('onRevisionChanged') private sharedTaskRevision: number = 0;
  @State private todayTasks: HomeFlowTask[] = [];
  @State private taskLoadHint: string = '';
  @State private currentDashboard: V03Dashboard | null = null;

  aboutToAppear(): void {
    this.loadTodayTasks();
  }

  private onRevisionChanged(): void {
    this.loadTodayTasks();
  }

  private async loadTodayTasks(): Promise<void> {
    const today: Date = new Date();
    const dateText: string = today.getFullYear().toString() + '-' +
      (today.getMonth() + 1).toString().padStart(2, '0') + '-' +
      today.getDate().toString().padStart(2, '0');
    try {
      this.currentDashboard = await HomeFlowV03.dashboard(dateText);
      this.todayTasks = this.currentDashboard.todayTasks;
      this.taskLoadHint = '';
    } catch (error) {
      this.todayTasks = [];
      this.currentDashboard = null;
      this.taskLoadHint = (error as Error).message;
    }
  }

  private taskIcon(category: string): Resource {
    if (category === 'trash') { return $r('app.media.hf_task_trash'); }
    if (category === 'dishes') { return $r('app.media.hf_task_dishes'); }
    if (category === 'bathroom') { return $r('app.media.hf_task_bathroom'); }
    if (category === 'laundry') { return $r('app.media.hf_task_laundry'); }
    if (category === 'supplies') { return $r('app.media.hf_task_supplies'); }
    return $r('app.media.hf_task_sweeping');
  }

  @Builder
  taskCard(task: HomeFlowTask) {
    Row({ space: 12 }) {
      Image(this.taskIcon(task.category))
        .width(43).height(43).objectFit(ImageFit.Contain)
        .padding(4).backgroundColor('#F0F5EC').borderRadius(12)
      Column({ space: 5 }) {
        Text(task.title)
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#30363A')
        Text('今天 ' + new Date(task.deadlineAt).getHours().toString().padStart(2, '0') + ':' +
          new Date(task.deadlineAt).getMinutes().toString().padStart(2, '0') + ' 前')
          .fontSize(12).fontColor('#798780')
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text(task.status === 'todo' ? '待完成' : (task.status === 'unassigned' ? '待分配' : task.status))
        .fontSize(12).fontWeight(FontWeight.Bold).fontColor('#34745D')
        .padding({ left: 12, right: 12, top: 7, bottom: 7 })
        .backgroundColor('#E7F3EA').borderRadius(10)
    }
    .padding(13).width('100%').height(78)
    .backgroundColor('#FFFFFF').borderRadius(16)
    .border({ width: 0.7, color: '#DFEAE2' })
    .shadow({ radius: 8, color: '#18536B56', offsetY: 5 })
    .onClick(() => {
      const routeParam: HomeFlowTaskRouteParam = { taskId: task.id };
      this.pageStack.pushPath({ name: 'TaskDetail', param: routeParam });
    })
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Image($r('app.media.hf_space_dorm'))
            .width(31).height(31).objectFit(ImageFit.Contain)
          Column({ space: 0 }) {
            Text(HomeFlowApi.currentSpace === null ? '当前空间' : HomeFlowApi.currentSpace.name)
              .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#34745D')
            Text('当前空间')
              .fontSize(11).fontColor('#798780')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1).margin({ left: 9 })
          Image($r('app.media.hf_notification'))
            .width(35).height(35).objectFit(ImageFit.Contain)
            .onClick(() => this.pageStack.pushPath({ name: 'Notifications' }))
        }
        .width('100%').margin({ top: 12, bottom: 10 })

        Row() {
          Column({ space: 5 }) {
            Text('今天有 ' + this.todayTasks.length.toString() + ' 项任务')
              .fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
            Text(this.taskLoadHint.length > 0 ? this.taskLoadHint : '一起把家务安排好')
              .fontSize(13).fontColor('#798780')
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
          Image($r('app.media.hf_home_task_board'))
            .width(112).height(95).objectFit(ImageFit.Contain)
        }
        .width('100%').height(112)
        .border({ width: 0.5, color: '#E0EAE1' })
        .margin({ bottom: 12 })

        Row() {
          Text('今日任务')
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#30363A')
            .layoutWeight(1)
          Text('查看全部 ›')
            .fontSize(13).fontWeight(FontWeight.Bold).fontColor('#4C9C7C')
            .onClick(() => this.pageStack.pushPath({ name: 'AllTasks' }))
        }
        .width('100%').margin({ bottom: 14 })

        ForEach(this.todayTasks, (task: HomeFlowTask) => {
          this.taskCard(task)
          Column() {}.height(10)
        }, (task: HomeFlowTask): string => task.id)
        if (this.todayTasks.length === 0) {
          Text('今天还没有任务').fontSize(14).fontColor('#798780').margin({ bottom: 8 })
        }

        Button() {
          Row({ space: 8 }) {
            Image($r('app.media.hf_space_create'))
              .width(25).height(25).objectFit(ImageFit.Contain)
            Text('新建任务')
              .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          }
        }
        .width('100%').height(46)
        .backgroundColor('#4C9C7C').borderRadius(12)
        .margin({ top: 13, bottom: 39 })
        .onClick(() => this.onCreateTask())

        Row() {
          Text('宿舍规则')
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#30363A')
            .layoutWeight(1)
          Text('查看全部 ›')
            .fontSize(13).fontWeight(FontWeight.Bold).fontColor('#4C9C7C')
            .onClick(() => this.pageStack.pushPath({ name: 'RuleProposals' }))
        }
        .width('100%').margin({ bottom: 12 })

        Column({ space: 11 }) {
          Row() {
            Image($r('app.media.hf_feature_consensus'))
              .width(29).height(29).objectFit(ImageFit.Contain)
            Text('一起遵守的小约定')
              .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#34745D')
              .layoutWeight(1).margin({ left: 7 })
            Text(this.currentDashboard === null ? '' :
              this.currentDashboard.activeRules.length.toString() + ' 条')
              .fontSize(12).fontColor('#798780')
          }
          .width('100%')
          Divider().color('#E4EBE5').strokeWidth(1)
          if (this.currentDashboard !== null) {
            ForEach(this.currentDashboard.activeRules, (rule: V03Rule) => {
              Text(rule.content).fontSize(13).fontColor('#30363A').width('100%')
            }, (rule: V03Rule): string => rule.id)
          }
          Row({ space: 11 }) {
            Button('新增规则')
              .layoutWeight(1).height(40)
              .fontSize(14).fontWeight(FontWeight.Bold)
              .backgroundColor('#4C9C7C').borderRadius(10)
              .onClick(() => this.pageStack.pushPath({ name: 'RuleProposals' }))
            Button('提议删除')
              .layoutWeight(1).height(40)
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor('#34745D').backgroundColor('#E7F3EA').borderRadius(10)
              .onClick(() => this.pageStack.pushPath({ name: 'RuleProposals' }))
          }
          .width('100%')
        }
        .padding(15).width('100%')
        .backgroundColor('#FFFFFF').borderRadius(16)
        .border({ width: 0.7, color: '#DFEAE2' })
        .shadow({ radius: 8, color: '#18536B56', offsetY: 5 })

        Row() {
          Text('公平统计')
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#30363A')
            .layoutWeight(1)
          Text('评分说明 ›')
            .fontSize(13).fontColor('#4C9C7C')
            .onClick(() => this.getUIContext().showAlertDialog({
              title: '评分说明',
              message: '完成审批后计分：预计分钟 ÷ 30 × 难度系数，详情见公平统计。',
              confirm: { value: '知道了', action: () => {} }
            }))
        }
        .width('100%').margin({ top: 37, bottom: 12 })

        Column({ space: 13 }) {
          Row() {
            Text('今日任务概览')
              .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#30363A')
              .layoutWeight(1)
            Button('查看详情')
              .height(30).fontSize(12)
              .fontColor('#34745D').backgroundColor('#E7F3EA')
              .onClick(() => this.pageStack.pushPath({ name: 'Statistics' }))
          }
          .width('100%')
          Text('共 ' + this.todayTasks.length.toString() + ' 项 · 已完成 ' +
            this.todayTasks.filter((task: HomeFlowTask): boolean => task.status === 'completed').length.toString() + ' 项')
            .fontSize(15).fontColor('#34745D').width('100%')
          Text(this.currentDashboard === null ? '正在读取统计' :
            '已完成 ' + this.currentDashboard.completionSummary.completedCount.toString() +
            ' 项 · 未读通知 ' + this.currentDashboard.unreadNotificationCount.toString() + ' 条')
            .fontSize(12).fontColor('#798780').width('100%')
          Button('查看详细统计')
            .width('100%').height(40)
            .fontColor('#34745D').backgroundColor('#E7F3EA')
            .onClick(() => this.pageStack.pushPath({ name: 'Statistics' }))
        }
        .padding(16).width('100%')
        .backgroundColor('#FFFFFF').borderRadius(16)
        .border({ width: 0.7, color: '#DFEAE2' })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 5, bottom: 26 })
    }
    .width('100%').height('100%')
    .backgroundColor('#FFF9F2')
  }
}
