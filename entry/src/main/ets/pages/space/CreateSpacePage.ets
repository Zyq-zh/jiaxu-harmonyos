import { HomeFlowApi, HomeFlowInvitation } from '../../api/HomeFlowApi';
import { HomeFlowClipboard } from '../../utils/HomeFlowClipboard';

@Component
export struct CreateSpacePage {
  pageStack: NavPathStack = new NavPathStack();
  @State private selectedScene: number = 0;
  @State private spaceNameText: string = '';
  @State private invitationText: string = '';
  @State private createHint: string = '';
  @State private joinHint: string = '';
  @State private showCreatedSheet: boolean = false;
  @State private createdInvitationCode: string = '';
  @State private createdExpiresAt: string = '';
  @State private submitting: boolean = false;

  private async createSpace(): Promise<void> {
    if (this.submitting) {
      return;
    }
    if (this.spaceNameText.trim().length < 2 || this.spaceNameText.trim().length > 40) {
      this.createHint = '空间名称需为 2—40 个字';
      return;
    }
    this.submitting = true;
    try {
      const invite: HomeFlowInvitation = await HomeFlowApi.createSpace(this.spaceNameText.trim(),
        this.selectedScene === 0 ? 'dorm' : 'shared');
      this.createdInvitationCode = invite.invitationCode;
      this.createdExpiresAt = invite.expiresAt;
      this.createHint = '';
      this.showCreatedSheet = true;
    } catch (error) {
      this.createHint = (error as Error).message;
    } finally {
      this.submitting = false;
    }
  }

  private async joinSpace(): Promise<void> {
    if (this.submitting) {
      return;
    }
    if (!/^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8}$/.test(this.invitationText.trim().toUpperCase())) {
      this.joinHint = '请输入创建者分享的 8 位邀请码';
      return;
    }
    this.submitting = true;
    try {
      await HomeFlowApi.joinSpace(this.invitationText.trim().toUpperCase());
      this.joinHint = '';
      this.pageStack.pushPath({ name: 'Main' });
    } catch (error) {
      this.joinHint = (error as Error).message;
    } finally {
      this.submitting = false;
    }
  }

  private async copyCreatedCode(): Promise<void> {
    try {
      await HomeFlowClipboard.copy(this.createdInvitationCode);
      this.getUIContext().showAlertDialog({
        message: '邀请码已复制', confirm: { value: '知道了', action: () => {} }
      });
    } catch (error) {
      this.getUIContext().showAlertDialog({
        message: '复制失败，请重试', confirm: { value: '知道了', action: () => {} }
      });
    }
  }

  @Builder
  createdContent() {
    Column({ space: 12 }) {
      Image($r('app.media.hf_space_created'))
        .width(76).height(76).objectFit(ImageFit.Contain)
      Text('空间创建成功')
        .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#30363A')
      Text('把邀请码分享给室友，一起加入新空间')
        .fontSize(14).fontColor('#798780')
      Text(this.createdInvitationCode)
        .fontSize(26).fontWeight(FontWeight.Bold).fontColor('#34745D')
        .letterSpacing(4)
        .width('100%').textAlign(TextAlign.Center)
        .padding(16).backgroundColor('#E8F5EC').borderRadius(14)
        .margin({ top: 10, bottom: 8 })
      Text('有效期至 ' + this.createdExpiresAt.substring(0, 10))
        .fontSize(12).fontColor('#798780')
      Button('复制邀请码')
        .width('100%').height(48)
        .fontColor('#FFFFFF').backgroundColor('#4C9C7C')
        .onClick(() => this.copyCreatedCode())
      Button('进入空间')
        .width('100%').height(44)
        .fontColor('#34745D').backgroundColor('#E8F5EC')
        .onClick(() => {
          this.showCreatedSheet = false;
          this.pageStack.pushPath({ name: 'Main' });
        })
    }
    .width('100%').height('100%').padding(24)
    .backgroundColor('#FFF9F2')
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Row() {
            Image($r('app.media.hf_space_back'))
              .width(38).height(38).objectFit(ImageFit.Contain)
              .onClick(() => this.pageStack.pop())
            Blank().layoutWeight(1)
          }
          .width('100%')
          Text('一起开启新空间')
            .fontSize(28).fontWeight(FontWeight.Bold).fontColor('#30363A')
            .width('100%').margin({ top: 8 })
          Text('创建空间，或用室友的邀请码直接加入。')
            .fontSize(13).fontColor('#9AA9A0')
            .width('100%').margin({ top: 4 })

          Image(this.selectedScene === 0 ? $r('app.media.hf_space_dorm_hero') : $r('app.media.hf_space_shared_hero'))
            .width('100%').height(170).objectFit(ImageFit.Contain)
            .margin({ top: 10, bottom: 2 })

          Column() {
            Row({ space: 10 }) {
              Image($r('app.media.hf_space_create'))
                .width(34).height(34).objectFit(ImageFit.Contain)
              Column({ space: 1 }) {
                Text('创建空间')
                  .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#30363A')
                Text('给室友们的共同生活起个名字')
                  .fontSize(12).fontColor('#9AA9A0')
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')

            Text('居住场景')
              .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A')
              .width('100%').margin({ top: 17, bottom: 7 })
            Row({ space: 8 }) {
              Row({ space: 6 }) {
                Image($r('app.media.hf_space_dorm'))
                  .width(30).height(30).objectFit(ImageFit.Contain)
                Text('宿舍')
                  .fontSize(16).fontWeight(FontWeight.Bold)
                  .fontColor(this.selectedScene === 0 ? '#34745D' : '#798780')
                Blank().layoutWeight(1)
                Image($r('app.media.hf_space_selected'))
                  .width(18).height(18).objectFit(ImageFit.Contain)
                  .opacity(this.selectedScene === 0 ? 1 : 0)
              }
              .padding({ left: 8, right: 8 })
              .layoutWeight(1).height(39)
              .backgroundColor(this.selectedScene === 0 ? '#E7F3EA' : '#F9FAF7')
              .borderRadius(10)
              .border({ width: this.selectedScene === 0 ? 1 : 0.5, color: this.selectedScene === 0 ? '#4C9C7C' : '#DEE6DE' })
              .onClick(() => this.selectedScene = 0)
              Row({ space: 6 }) {
                Image($r('app.media.hf_space_shared_rental'))
                  .width(30).height(30).objectFit(ImageFit.Contain)
                Text('合租')
                  .fontSize(16).fontWeight(FontWeight.Bold)
                  .fontColor(this.selectedScene === 1 ? '#34745D' : '#798780')
                Blank().layoutWeight(1)
                Image($r('app.media.hf_space_selected'))
                  .width(18).height(18).objectFit(ImageFit.Contain)
                  .opacity(this.selectedScene === 1 ? 1 : 0)
              }
              .padding({ left: 8, right: 8 })
              .layoutWeight(1).height(39)
              .backgroundColor(this.selectedScene === 1 ? '#E7F3EA' : '#F9FAF7')
              .borderRadius(10)
              .border({ width: this.selectedScene === 1 ? 1 : 0.5, color: this.selectedScene === 1 ? '#4C9C7C' : '#DEE6DE' })
              .onClick(() => this.selectedScene = 1)
            }
            .width('100%')

            Text('空间名称')
              .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A')
              .width('100%').margin({ top: 14, bottom: 6 })
            TextInput({ placeholder: this.selectedScene === 0 ? '例如：302 宿舍' : '例如：阳光合租屋', text: this.spaceNameText })
              .maxLength(40)
              .height(42).width('100%')
              .fontSize(14).placeholderColor('#A3AEA6')
              .backgroundColor('#FFFFFF').borderRadius(10)
              .border({ width: 1, color: '#DEE6DE' })
              .onChange((value: string) => {
                this.spaceNameText = value;
                this.createHint = '';
              })
            if (this.createHint.length > 0) {
              Text(this.createHint).fontSize(12).fontColor('#BF715D').width('100%')
            }
            Button(this.submitting ? '请稍候…' : '创建空间')
              .width('100%').height(44)
              .fontSize(16).fontWeight(FontWeight.Bold)
              .backgroundColor('#4C9C7C').borderRadius(10)
              .enabled(!this.submitting)
              .margin({ top: 12 })
              .onClick(() => this.createSpace())
          }
          .padding(16).width('100%')
          .backgroundColor('#FFFFFF').borderRadius(18)
          .shadow({ radius: 12, color: '#1A536B56', offsetY: 6 })

          Column() {
            Row({ space: 10 }) {
              Image($r('app.media.hf_space_invitation'))
                .width(34).height(34).objectFit(ImageFit.Contain)
              Column({ space: 1 }) {
                Text('有邀请码？直接加入')
                  .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#30363A')
                Text('邀请码由创建者分享，加入后自动匹配场景')
                  .fontSize(12).fontColor('#9AA9A0')
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            TextInput({ placeholder: '请输入邀请码', text: this.invitationText })
              .maxLength(8)
              .height(42).width('100%')
              .fontSize(14).placeholderColor('#A3AEA6')
              .backgroundColor('#FFFFFF').borderRadius(10)
              .border({ width: 1, color: '#DEE6DE' })
              .margin({ top: 17 })
              .onChange((value: string) => {
                this.invitationText = value;
                this.joinHint = '';
              })
            if (this.joinHint.length > 0) {
              Text(this.joinHint).fontSize(12).fontColor('#BF715D').width('100%')
            }
            Button(this.submitting ? '请稍候…' : '加入空间')
              .width('100%').height(44)
              .fontSize(16).fontWeight(FontWeight.Bold)
              .fontColor('#34745D').backgroundColor('#E7F3EA')
              .border({ width: 1, color: '#4C9C7C' }).borderRadius(10)
              .margin({ top: 12 })
              .enabled(!this.submitting)
              .onClick(() => this.joinSpace())
          }
          .padding(16).width('100%')
          .backgroundColor('#FFFFFF').borderRadius(18)
          .shadow({ radius: 12, color: '#1A536B56', offsetY: 6 })
          .margin({ top: 12 })

          Text('加入成功后，即可看到室友共享的日程与任务')
            .fontSize(12).fontColor('#A3AEA6')
            .margin({ top: 16, bottom: 15 })
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 14, bottom: 20 })
      }
      .width('100%').height('100%')
      .bindSheet($$this.showCreatedSheet, this.createdContent, {
        height: SheetSize.MEDIUM, dragBar: false, backgroundColor: '#FFF9F2'
      })
    }
    .hideTitleBar(true)
    .backgroundColor('#FFF9F2')
  }
}
