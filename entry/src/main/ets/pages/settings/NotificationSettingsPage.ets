import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { HomeFlowV03, V03NotificationPreferences } from '../../api/HomeFlowV03';

@Component
export struct NotificationSettingsPage {
  pageStack: NavPathStack = new NavPathStack();
  @State private tasksOn: boolean = true;
  @State private reviewsOn: boolean = true;
  @State private swapsOn: boolean = true;
  @State private rulesOn: boolean = true;
  @State private summaryOn: boolean = false;
  @State private systemEnabled: boolean = true;
  @State private prefVersion: number = 0;
  @State private hint: string = '';

  aboutToAppear(): void { this.checkSystemPermission(); this.loadPreferences(); }

  private async loadPreferences(): Promise<void> {
    try {
      const pref: V03NotificationPreferences = await HomeFlowV03.notificationPreferences();
      this.prefVersion = pref.version;
      this.tasksOn = pref.tasks; this.reviewsOn = pref.reviews;
      this.swapsOn = pref.swaps; this.rulesOn = pref.rules;
      this.summaryOn = pref.weeklySummary;
      this.hint = '';
    } catch (error) { this.hint = (error as Error).message; }
  }

  private async checkSystemPermission(): Promise<void> {
    try { this.systemEnabled = await notificationManager.isNotificationEnabled(); }
    catch (error) { this.systemEnabled = false; }
  }

  private async openSystemSettings(): Promise<void> {
    try {
      const host: Context | undefined = this.getUIContext().getHostContext();
      if (host === undefined) { throw new Error('系统设置不可用'); }
      await notificationManager.openNotificationSettings(host as common.UIAbilityContext);
      await this.checkSystemPermission();
    } catch (error) {
      this.getUIContext().showAlertDialog({
        message: '无法打开系统通知设置，请手动在系统设置中开启家序通知。',
        confirm: { value: '知道了', action: () => {} }
      });
    }
  }

  private isPreferenceOn(index: number): boolean {
    if (index === 0) { return this.tasksOn; }
    if (index === 1) { return this.reviewsOn; }
    if (index === 2) { return this.swapsOn; }
    if (index === 3) { return this.rulesOn; }
    return this.summaryOn;
  }

  private async flip(index: number): Promise<void> {
    if (!this.systemEnabled && !this.isPreferenceOn(index)) {
      this.getUIContext().showAlertDialog({
        title: '系统通知尚未开启', message: '可先设置应用内偏好，手机推送还需要系统通知权限。',
        primaryButton: { value: '暂不开启', action: () => {} },
        secondaryButton: { value: '前往系统设置', action: () => this.openSystemSettings() }
      });
    }
    if (index === 0) { this.tasksOn = !this.tasksOn; }
    else if (index === 1) { this.reviewsOn = !this.reviewsOn; }
    else if (index === 2) { this.swapsOn = !this.swapsOn; }
    else if (index === 3) { this.rulesOn = !this.rulesOn; }
    else { this.summaryOn = !this.summaryOn; }
    const input: V03NotificationPreferences = { version: this.prefVersion, tasks: this.tasksOn,
      reviews: this.reviewsOn, swaps: this.swapsOn, rules: this.rulesOn,
      weeklySummary: this.summaryOn };
    try {
      const saved: V03NotificationPreferences = await HomeFlowV03.saveNotificationPreferences(input);
      this.prefVersion = saved.version;
      this.hint = '偏好已保存；手机推送取决于系统权限和服务配置';
    } catch (error) {
      this.hint = (error as Error).message;
      await this.loadPreferences();
    }
  }

  @Builder
  settingRow(title: string, subtitle: string, index: number) {
    Row({ space: 12 }) {
      Column({ space: 5 }) {
        Text(title).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#30363A')
        Text(subtitle).fontSize(12).fontColor('#798780').maxLines(2)
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Button(this.isPreferenceOn(index) ? '开' : '关')
        .width(55).height(33).fontSize(13)
        .fontColor(this.isPreferenceOn(index) ? '#FFFFFF' : '#798780')
        .backgroundColor(this.isPreferenceOn(index) ? '#4C9C7C' : '#DFE7E0')
        .borderRadius(17).onClick(() => this.flip(index))
    }.padding(16).width('100%').height(74)
      .backgroundColor('#FFFFFF').borderRadius(15)
      .border({ width: 1, color: '#DCE8DF' }).margin({ bottom: 10 })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Row({ space: 12 }) {
            Image($r('app.media.hf_space_back')).width(38).height(38)
              .onClick(() => this.pageStack.pop())
            Column({ space: 2 }) {
              Text('通知设置').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
              Text('只接收与你有关的提醒').fontSize(13).fontColor('#798780')
            }.alignItems(HorizontalAlign.Start)
          }.width('100%').margin({ top: 12, bottom: 22 })
          Column({ space: 4 }) {
            Text('通知偏好').fontSize(15).fontWeight(FontWeight.Bold)
              .fontColor('#34745D').width('100%')
            Text('关闭开关只影响系统推送；应用内通知仍会保存。')
              .fontSize(12).fontColor('#798780').width('100%')
          }.padding(15).width('100%').backgroundColor('#EFF6EE').borderRadius(13)
          if (!this.systemEnabled) {
            Button('系统通知未开启 · 前往设置')
              .width('100%').height(43).fontColor('#BF715D')
              .backgroundColor('#FFF0EA').margin({ top: 10 })
              .onClick(() => this.openSystemSettings())
          }
          Text('任务与审批').fontSize(19).fontWeight(FontWeight.Bold)
            .fontColor('#30363A').width('100%').margin({ top: 25, bottom: 11 })
          this.settingRow('任务分配与截止提醒', '排班发布、即将到期', 0)
          this.settingRow('完成照片审批', '有室友提交前后照片等待我审核', 1)
          this.settingRow('换班申请', '有人向我申请换班或回应我的申请', 2)
          Text('空间表决').fontSize(19).fontWeight(FontWeight.Bold)
            .fontColor('#30363A').width('100%').margin({ top: 19, bottom: 11 })
          this.settingRow('规则与提案表决', '需要我投票或表决结果已公布', 3)
          this.settingRow('每周安排摘要', '每周一汇总本周任务', 4)
          Text(this.hint)
            .fontSize(12).fontColor('#798780').width('100%').margin({ top: 18 })
        }.padding({ left: 24, right: 24, top: 5, bottom: 30 }).width('100%')
      }.width('100%').height('100%')
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
