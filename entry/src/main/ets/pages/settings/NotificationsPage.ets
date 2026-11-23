import { HomeFlowV03, V03Notification } from '../../api/HomeFlowV03';
import { HomeFlowTaskRouteParam } from '../../api/HomeFlowApi';

@Component
export struct NotificationsPage {
  pageStack: NavPathStack = new NavPathStack();
  @State private category: number = 0;
  @State private notificationList: V03Notification[] = [];
  @State private hint: string = '';

  aboutToAppear(): void { this.load(); }

  private async load(): Promise<void> {
    try { this.notificationList = await HomeFlowV03.notifications(); this.hint = ''; }
    catch (error) { this.hint = (error as Error).message; }
  }

  private visible(): V03Notification[] {
    if (this.category === 0) { return this.notificationList; }
    return this.notificationList.filter((item: V03Notification): boolean => {
      if (this.category === 1) { return item.resourceType === 'task'; }
      if (this.category === 2) { return item.type.indexOf('swap') >= 0; }
      return item.resourceType === 'rule_proposal';
    });
  }

  private async openNotification(item: V03Notification): Promise<void> {
    try {
      await HomeFlowV03.readNotification(item.id);
      await this.load();
      if (item.resourceType === 'task') {
        const routeParam: HomeFlowTaskRouteParam = { taskId: item.resourceId };
        this.pageStack.pushPath({ name: 'TaskDetail', param: routeParam });
      } else if (item.resourceType === 'rule_proposal') {
        this.pageStack.pushPath({ name: 'RuleProposals' });
      } else {
        this.hint = '请到相关页面查看最新状态';
      }
    } catch (error) { this.hint = (error as Error).message; }
  }

  @Builder
  filterButton(label: string, value: number) {
    Button(label).layoutWeight(1).height(36).fontSize(12)
      .fontColor(this.category === value ? '#FFFFFF' : '#34745D')
      .backgroundColor(this.category === value ? '#4C9C7C' : '#E7F3EA')
      .onClick(() => this.category = value)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Row({ space: 12 }) {
            Image($r('app.media.hf_space_back')).width(38).height(38)
              .onClick(() => this.pageStack.pop())
            Text('通知中心').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
          }.width('100%').margin({ top: 12, bottom: 9 })
          Text('任务、审批、换班与规则提醒').fontSize(13)
            .fontColor('#798780').width('100%')
          Row({ space: 7 }) {
            this.filterButton('全部', 0)
            this.filterButton('任务', 1)
            this.filterButton('换班', 2)
            this.filterButton('规则', 3)
          }.width('100%').margin({ top: 24, bottom: 20 })
          ForEach(this.visible(), (item: V03Notification) => {
            Column({ space: 7 }) {
              Text(item.type).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#30363A')
              Text(item.createdAt.substring(0, 16) + (item.readAt === null ? ' · 未读' : ' · 已读'))
                .fontSize(12).fontColor('#798780')
            }.padding(17).width('100%').backgroundColor('#FFFFFF')
              .borderRadius(13).margin({ bottom: 8 })
              .onClick(() => this.openNotification(item))
          }, (item: V03Notification): string => item.id)
          if (this.visible().length === 0) {
            Text('暂时没有通知').fontSize(16).fontColor('#798780')
              .padding(27).width('100%').backgroundColor('#FFFFFF').borderRadius(17)
          }
          if (this.hint.length > 0) {
            Text(this.hint).fontSize(13).fontColor('#BF715D')
          }
          Button('通知设置').width('100%').height(46)
            .fontColor('#34745D').backgroundColor('#E7F3EA').margin({ top: 19 })
            .onClick(() => this.pageStack.pushPath({ name: 'NotificationSettings' }))
        }.padding({ left: 24, right: 24, top: 5, bottom: 25 }).width('100%')
      }.width('100%').height('100%')
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
