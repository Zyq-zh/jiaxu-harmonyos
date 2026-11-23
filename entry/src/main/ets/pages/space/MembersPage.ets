import { HomeFlowApi, HomeFlowInvitation, HomeFlowMember } from '../../api/HomeFlowApi';
import { HomeFlowClipboard } from '../../utils/HomeFlowClipboard';

@Component
export struct MembersPage {
  pageStack: NavPathStack = new NavPathStack();
  @State private memberList: HomeFlowMember[] = [];
  @State private loadHint: string = '';
  @State private loading: boolean = false;
  @State private invitationCode: string = '';
  @State private invitationExpiresAt: string = '';
  @State private showInvitation: boolean = false;
  @State private permissionBusyId: string = '';

  aboutToAppear(): void {
    this.loadMembers();
  }

  private async loadMembers(): Promise<void> {
    if (this.loading) { return; }
    this.loading = true;
    try {
      this.memberList = await HomeFlowApi.members();
      this.loadHint = '';
    } catch (error) {
      this.loadHint = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async openInvitation(): Promise<void> {
    try {
      const invite: HomeFlowInvitation = await HomeFlowApi.invitation();
      this.invitationCode = invite.invitationCode;
      this.invitationExpiresAt = invite.expiresAt;
      this.showInvitation = true;
    } catch (error) {
      this.loadHint = (error as Error).message;
    }
  }

  private async copyInvitation(): Promise<void> {
    try {
      await HomeFlowClipboard.copy(this.invitationCode);
      this.getUIContext().showAlertDialog({
        message: '邀请码已复制', confirm: { value: '知道了', action: () => {} }
      });
    } catch (error) {
      this.getUIContext().showAlertDialog({
        message: '复制失败，请重试', confirm: { value: '知道了', action: () => {} }
      });
    }
  }

  private async rotateCode(): Promise<void> {
    try {
      const invite: HomeFlowInvitation = await HomeFlowApi.rotateInvitation();
      this.invitationCode = invite.invitationCode;
      this.invitationExpiresAt = invite.expiresAt;
    } catch (error) {
      this.getUIContext().showAlertDialog({
        message: (error as Error).message,
        confirm: { value: '知道了', action: () => {} }
      });
    }
  }

  private async togglePermission(member: HomeFlowMember): Promise<void> {
    if (this.permissionBusyId.length > 0) { return; }
    this.permissionBusyId = member.id;
    try {
      const updated: HomeFlowMember = await HomeFlowApi.updatePermission(member.id,
        !member.canPublishSchedule, member.version);
      this.memberList = this.memberList.map((item: HomeFlowMember): HomeFlowMember =>
        item.id === updated.id ? updated : item);
      this.loadHint = '';
    } catch (error) {
      this.loadHint = (error as Error).message;
      this.loadMembers();
    } finally {
      this.permissionBusyId = '';
    }
  }

  @Builder
  invitationSheet() {
    Column({ space: 16 }) {
      Row() {
        Text('管理邀请码').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#30363A').layoutWeight(1)
        Text('取消').fontSize(15).fontColor('#798780').onClick(() => this.showInvitation = false)
      }.width('100%')
      Text('只向你主动邀请的室友分享').fontSize(13).fontColor('#798780').width('100%')
      Text(this.invitationCode).fontSize(26).fontWeight(FontWeight.Bold)
        .fontColor('#34745D').letterSpacing(4).textAlign(TextAlign.Center)
        .padding(18).width('100%').backgroundColor('#E7F3EA').borderRadius(13)
      Text('有效期至 ' + this.invitationExpiresAt.substring(0, 10))
        .fontSize(12).fontColor('#798780').width('100%').textAlign(TextAlign.Center)
      Button('复制邀请码').width('100%').height(49).backgroundColor('#4C9C7C')
        .onClick(() => this.copyInvitation())
      Button('更换邀请码').width('100%').height(45)
        .fontColor('#34745D').backgroundColor('#E7F3EA')
        .onClick(() => this.getUIContext().showAlertDialog({
          title: '更换邀请码？', message: '更换后旧邀请码立即失效。',
          primaryButton: { value: '保留', action: () => {} },
          secondaryButton: { value: '更换', action: () => this.rotateCode() }
        }))
    }.width('100%').padding(24).backgroundColor('#FFF9F2')
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Row({ space: 13 }) {
            Image($r('app.media.hf_space_back')).width(38).height(38)
              .onClick(() => this.pageStack.pop())
            Column({ space: 2 }) {
              Text('当前空间与成员').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#30363A')
              Text(HomeFlowApi.currentSpace === null ? '' : HomeFlowApi.currentSpace.name + ' · ' +
                (HomeFlowApi.currentSpace.myRole === 'creator' ? '创建者视角' : '成员视角'))
                .fontSize(13).fontColor('#798780')
            }.alignItems(HorizontalAlign.Start)
          }.width('100%').margin({ top: 12, bottom: 24 })

          Row({ space: 18 }) {
            Image(HomeFlowApi.currentSpace !== null && HomeFlowApi.currentSpace.scene === 'shared' ?
              $r('app.media.hf_space_shared_rental') : $r('app.media.hf_space_dorm'))
              .width(70).height(70).objectFit(ImageFit.Contain)
            Column({ space: 7 }) {
              Text(HomeFlowApi.currentSpace === null ? '未加入空间' : HomeFlowApi.currentSpace.name)
                .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#30363A')
              Text(HomeFlowApi.currentSpace !== null && HomeFlowApi.currentSpace.scene === 'shared' ?
                '合租场景' : '宿舍场景').fontSize(13).fontColor('#798780')
            }.alignItems(HorizontalAlign.Start)
          }.padding(19).width('100%').backgroundColor('#E7F3EA').borderRadius(17)

          Row() {
            Text('空间成员').fontSize(19).fontWeight(FontWeight.Bold).fontColor('#30363A').layoutWeight(1)
            Text('共 ' + this.memberList.length.toString() + ' 人').fontSize(13).fontColor('#798780')
          }.width('100%').margin({ top: 26, bottom: 12 })
          Column() {
            ForEach(this.memberList, (member: HomeFlowMember) => {
              Row({ space: 12 }) {
                Image($r('app.media.hf_tab_settings')).width(42).height(42).objectFit(ImageFit.Contain)
                Column({ space: 3 }) {
                  Text(member.nickname).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#30363A')
                  Text((HomeFlowApi.currentUser !== null && HomeFlowApi.currentUser.id === member.userId ? '我 · ' : '') +
                    (member.role === 'creator' ? '创建者' : '成员'))
                    .fontSize(12).fontColor('#798780')
                }.alignItems(HorizontalAlign.Start)
                Blank().layoutWeight(1)
                if (HomeFlowApi.currentSpace !== null && HomeFlowApi.currentSpace.myRole === 'creator' &&
                  member.role !== 'creator') {
                  Button(member.canPublishSchedule ? '可发布排班' : '不可发布')
                    .height(31).fontSize(11)
                    .fontColor('#34745D').backgroundColor('#E7F3EA')
                    .enabled(this.permissionBusyId.length === 0)
                    .onClick(() => this.togglePermission(member))
                }
              }.width('100%').height(66)
              Divider().strokeWidth(1).color('#E2EAE3')
            }, (member: HomeFlowMember): string => member.id)
            if (this.memberList.length === 0) {
              Text(this.loading ? '正在加载成员…' : '暂无成员信息')
                .fontSize(14).fontColor('#798780').padding(18)
            }
          }.padding({ left: 16, right: 16 }).width('100%')
            .backgroundColor('#FFFFFF').borderRadius(16)
            .border({ width: 1, color: '#DCE8DF' })
          if (this.loadHint.length > 0) {
            Text(this.loadHint).fontSize(13).fontColor('#BF715D').margin({ top: 9 })
            Button('重试').backgroundColor('#4C9C7C').margin({ top: 8 })
              .onClick(() => this.loadMembers())
          }
          Text('邀请信息').fontSize(19).fontWeight(FontWeight.Bold)
            .fontColor('#30363A').width('100%').margin({ top: 27, bottom: 12 })
          if (HomeFlowApi.currentSpace !== null && HomeFlowApi.currentSpace.myRole === 'creator') {
            Row({ space: 12 }) {
              Image($r('app.media.hf_space_invitation')).width(38).height(38)
              Column({ space: 4 }) {
                Text('管理邀请码').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#30363A')
                Text('查看并复制，发送给要加入的室友').fontSize(12).fontColor('#798780')
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text('›').fontSize(22).fontColor('#34745D')
            }.padding(16).width('100%').backgroundColor('#FFFFFF').borderRadius(16)
              .border({ width: 1, color: '#DCE8DF' })
              .onClick(() => this.openInvitation())
          } else {
            Text('邀请码由空间创建者分享。')
              .fontSize(14).fontColor('#798780').padding(17).width('100%')
              .backgroundColor('#FFFFFF').borderRadius(16)
          }
          Text('邀请码只向你主动邀请的人分享。新成员输入后会直接加入当前空间。')
            .fontSize(12).fontColor('#34745D').width('100%')
            .padding(14).backgroundColor('#EFF6EE').borderRadius(13)
            .margin({ top: 48, bottom: 20 })
        }.width('100%').padding({ left: 24, right: 24, top: 5 })
      }.width('100%').height('100%')
        .bindSheet($$this.showInvitation, this.invitationSheet, {
          height: SheetSize.MEDIUM, dragBar: false, backgroundColor: '#FFF9F2'
        })
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
