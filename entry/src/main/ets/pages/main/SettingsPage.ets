import { HomeFlowApi } from '../../api/HomeFlowApi';
import { HomeFlowDraftStore } from '../../utils/HomeFlowDraftStore';

@Component
export struct SettingsPage {
  pageStack: NavPathStack = new NavPathStack();
  @StorageLink('homeflowNickname') private nicknameDisplay: string = '';

  private signOut(): void {
    this.getUIContext().showAlertDialog({
      title: '退出当前账号？',
      message: '退出后需要重新登录，当前页面中的未保存内容将保留在本次会话中。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '退出登录', action: () => this.logout() }
    });
  }

  private async logout(): Promise<void> {
    try {
      await HomeFlowApi.logout();
    } catch (error) {
      // Local session is cleared by HomeFlowApi even if the server is unavailable.
    } finally {
      HomeFlowDraftStore.clear();
      this.pageStack.clear();
    }
  }

  @Builder
  settingsRow(icon: Resource, title: string, subtitle: string, route: string) {
    Row({ space: 13 }) {
      Image(icon)
        .width(45).height(45).objectFit(ImageFit.Contain)
      Column({ space: 4 }) {
        Text(title)
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#30363A')
        Text(subtitle)
          .fontSize(12).fontColor('#798780')
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text('›')
        .fontSize(23).fontColor('#34745D')
    }
    .padding({ left: 15, right: 16 }).width('100%').height(68)
    .backgroundColor('#FFFFFF').borderRadius(15)
    .border({ width: 0.8, color: '#DFEAE2' })
    .shadow({ radius: 8, color: '#18536B56', offsetY: 5 })
    .onClick(() => this.pageStack.pushPath({ name: route }))
  }

  build() {
    Scroll() {
      Column() {
        Text('个人设置')
          .fontSize(26).fontWeight(FontWeight.Bold).fontColor('#30363A')
          .width('100%').margin({ top: 12 })
        Text('资料、提醒与私有草稿')
          .fontSize(13).fontColor('#798780')
          .width('100%').margin({ top: 3, bottom: 20 })

        Row({ space: 19 }) {
          Image($r('app.media.hf_tab_settings'))
            .width(75).height(75).objectFit(ImageFit.Contain)
          Column({ space: 6 }) {
            Text(this.nicknameDisplay.length === 0 ? '我' : this.nicknameDisplay)
              .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#30363A')
            Text(HomeFlowApi.currentSpace === null ? '未加入空间' :
              HomeFlowApi.currentSpace.name + ' · ' +
              (HomeFlowApi.currentSpace.myRole === 'creator' ? '创建者' : '成员'))
              .fontSize(13).fontColor('#798780')
            Button('编辑资料 ›')
              .height(34).fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor('#34745D').backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#D3E6D9' }).borderRadius(10)
              .margin({ top: 5 })
              .onClick(() => this.pageStack.pushPath({ name: 'Profile' }))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .padding(22).width('100%').height(127)
        .backgroundColor('#E7F3EA').borderRadius(18)
        .shadow({ radius: 10, color: '#20536B56', offsetY: 6 })

        Text('我的内容')
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#30363A')
          .width('100%').margin({ top: 26, bottom: 12 })
        this.settingsRow($r('app.media.hf_tab_communication'),
          '私有沟通草稿', '本次会话 · ' + HomeFlowDraftStore.all().length.toString() + ' 条', 'Drafts')

        Text('空间与提醒')
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#30363A')
          .width('100%').margin({ top: 23, bottom: 12 })
        this.settingsRow($r('app.media.hf_space_dorm'),
          '当前空间与成员', HomeFlowApi.currentSpace === null ? '未加入空间' :
          HomeFlowApi.currentSpace.name + ' · 查看成员和邀请信息', 'Members')
        Column() {}.height(9)
        this.settingsRow($r('app.media.hf_notification'),
          '通知设置', '任务审批与提案提醒', 'NotificationSettings')

        Text('账号与隐私')
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#30363A')
          .width('100%').margin({ top: 23, bottom: 12 })
        this.settingsRow($r('app.media.hf_privacy_lock'),
          '隐私与数据', '照片和私有草稿的可见范围', 'Privacy')

        Button('退出登录')
          .width('100%').height(46)
          .fontSize(16).fontWeight(FontWeight.Bold)
          .fontColor('#BF715D').backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#F0D9D0' }).borderRadius(12)
          .margin({ top: 26 })
          .onClick(() => this.signOut())
        Text('家序 v1.0')
          .fontSize(12).fontColor('#9AAD9F')
          .margin({ top: 14, bottom: 10 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 5, bottom: 18 })
    }
    .width('100%').height('100%')
    .backgroundColor('#FFF9F2')
  }
}
