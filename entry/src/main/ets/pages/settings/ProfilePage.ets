import { HomeFlowApi, HomeFlowUser } from '../../api/HomeFlowApi';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { cameraPicker, camera } from '@kit.CameraKit';

@Component
export struct ProfilePage {
  pageStack: NavPathStack = new NavPathStack();
  @State private nicknameText: string = '';
  @State private originalNickname: string = '';
  @State private userVersion: number = 1;
  @State private formHint: string = '';
  @State private saving: boolean = false;
  @State private avatarUri: string = '';

  aboutToAppear(): void {
    if (HomeFlowApi.currentUser !== null) {
      this.nicknameText = HomeFlowApi.currentUser.nickname;
      this.originalNickname = HomeFlowApi.currentUser.nickname;
      this.userVersion = HomeFlowApi.currentUser.version;
    }
  }

  private returnPage(): void {
    if (this.nicknameText.trim() === this.originalNickname && this.avatarUri.length === 0) {
      this.pageStack.pop();
      return;
    }
    this.getUIContext().showAlertDialog({
      title: '放弃未保存的修改？', message: '昵称修改尚未保存。',
      primaryButton: { value: '继续编辑', action: () => {} },
      secondaryButton: { value: '放弃修改', action: () => this.pageStack.pop() }
    });
  }

  private async chooseAvatar(): Promise<void> {
    try {
      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
      if (result.photoUris.length > 0) { this.avatarUri = result.photoUris[0]; }
    } catch (error) {
      this.formHint = '选择头像失败，请重试';
    }
  }

  private async captureAvatar(): Promise<void> {
    try {
      const host: Context | undefined = this.getUIContext().getHostContext();
      if (host === undefined) { throw new Error('无法打开相机'); }
      const profile: cameraPicker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_FRONT
      };
      const result: cameraPicker.PickerResult = await cameraPicker.pick(host,
        [cameraPicker.PickerMediaType.PHOTO], profile);
      if (result.resultCode === 0 && result.resultUri.length > 0) {
        this.avatarUri = result.resultUri;
      }
    } catch (error) {
      this.formHint = '拍照失败，请重试或从相册选择';
    }
  }

  private async saveProfile(): Promise<void> {
    if (this.saving) { return; }
    const nickname: string = this.nicknameText.trim();
    if (nickname.length < 2 || nickname.length > 12) {
      this.formHint = '昵称需为 2—12 个字';
      return;
    }
    if (nickname === this.originalNickname) {
      if (this.avatarUri.length > 0) {
        this.getUIContext().showAlertDialog({
          title: '头像尚未保存', message: '头像上传接口接入后才能将预览照片保存到账号。',
          confirm: { value: '知道了', action: () => {} }
        });
      } else {
        this.pageStack.pop();
      }
      return;
    }
    this.saving = true;
    try {
      const user: HomeFlowUser = await HomeFlowApi.updateNickname(nickname, this.userVersion);
      this.originalNickname = user.nickname;
      this.userVersion = user.version;
      this.formHint = '';
      if (this.avatarUri.length > 0) {
        this.getUIContext().showAlertDialog({
          title: '昵称已保存', message: '头像只在本机预览，上传接口接入后才能保存头像。',
          confirm: { value: '知道了', action: () => this.pageStack.pop() }
        });
      } else {
        this.pageStack.pop();
      }
    } catch (error) {
      this.formHint = (error as Error).message;
    } finally {
      this.saving = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            Row({ space: 14 }) {
              Image($r('app.media.hf_space_back'))
                .width(38).height(38).objectFit(ImageFit.Contain)
                .onClick(() => this.returnPage())
              Column({ space: 2 }) {
                Text('编辑资料').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
                Text('头像和昵称会显示给室友').fontSize(13).fontColor('#798780')
              }.alignItems(HorizontalAlign.Start)
            }.width('100%').margin({ top: 12, bottom: 24 })

            Text('头像').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#30363A').width('100%')
            Image(this.avatarUri.length > 0 ? this.avatarUri : $r('app.media.hf_tab_settings'))
              .width(120).height(120).objectFit(ImageFit.Contain)
              .padding(18).backgroundColor('#E7F3EA').borderRadius(60)
              .margin({ top: 14 })
            Row({ space: 8 }) {
              Button('拍摄头像').layoutWeight(1).height(39)
                .fontSize(13).fontColor('#34745D').backgroundColor('#FFFFFF')
                .border({ width: 1, color: '#DCE8DF' }).borderRadius(10)
                .onClick(() => this.captureAvatar())
              Button('从相册选择').layoutWeight(1).height(39)
                .fontSize(13).fontColor('#34745D').backgroundColor('#FFFFFF')
                .border({ width: 1, color: '#DCE8DF' }).borderRadius(10)
                .onClick(() => this.chooseAvatar())
            }.width('100%').margin({ top: 9 })
            Text('可在本机预览；头像上传接口接入后才能保存')
              .fontSize(12).fontColor('#798780').margin({ top: 8, bottom: 29 })

            Text('昵称').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#30363A').width('100%')
            TextInput({ placeholder: '请输入昵称', text: this.nicknameText })
              .maxLength(12).height(54).width('100%')
              .backgroundColor('#FFFFFF').borderRadius(13)
              .border({ width: 1, color: '#DCE8DF' })
              .margin({ top: 9 })
              .onChange((value: string) => { this.nicknameText = value; this.formHint = ''; })
            Text(this.nicknameText.length.toString() + ' / 12')
              .fontSize(12).fontColor('#798780').width('100%').textAlign(TextAlign.End)
            if (this.formHint.length > 0) {
              Text(this.formHint).fontSize(12).fontColor('#BF715D').width('100%')
            }
            Text('空间身份').fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor('#30363A').width('100%').margin({ top: 28, bottom: 9 })
            Text(HomeFlowApi.currentSpace === null ? '未加入空间' :
              HomeFlowApi.currentSpace.name + ' · ' +
              (HomeFlowApi.currentSpace.myRole === 'creator' ? '创建者' : '成员'))
              .fontSize(15).fontColor('#798780').width('100%')
              .padding(16).backgroundColor('#F4F7F2').borderRadius(13)
            Text('修改昵称后，室友将在任务和表决记录中看到新昵称。')
              .fontSize(12).fontColor('#34745D').width('100%')
              .padding(14).backgroundColor('#EFF6EE').borderRadius(13)
              .margin({ top: 28, bottom: 20 })
          }.width('100%').padding({ left: 24, right: 24, top: 4 })
        }.layoutWeight(1).width('100%')
        Button(this.saving ? '保存中…' : '保存昵称')
          .width('100%').height(50).fontSize(17).fontWeight(FontWeight.Bold)
          .backgroundColor('#4C9C7C').borderRadius(13).enabled(!this.saving)
          .onClick(() => this.saveProfile())
          .margin({ bottom: 10 })
      }.width('100%').height('100%').padding({ left: 24, right: 24 })
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
