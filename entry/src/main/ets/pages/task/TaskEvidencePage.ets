import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { cameraPicker, camera } from '@kit.CameraKit';
import { HomeFlowApi, HomeFlowTask, HomeFlowTaskDetailData } from '../../api/HomeFlowApi';

@Component
export struct TaskEvidencePage {
  pageStack: NavPathStack = new NavPathStack();
  taskId: string = '';
  @State private task: HomeFlowTask | null = null;
  @State private beforeUri: string = '';
  @State private afterUri: string = '';
  @State private hint: string = '';

  aboutToAppear(): void { this.load(); }

  private async load(): Promise<void> {
    if (this.taskId.length === 0) { return; }
    try {
      const detail: HomeFlowTaskDetailData = await HomeFlowApi.taskDetail(this.taskId);
      this.task = detail.task;
      this.hint = '';
    } catch (error) {
      this.hint = (error as Error).message;
    }
  }

  private async pick(before: boolean): Promise<void> {
    try {
      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
      if (result.photoUris.length > 0) {
        if (before) { this.beforeUri = result.photoUris[0]; }
        else { this.afterUri = result.photoUris[0]; }
      }
    } catch (error) {
      this.hint = '选择照片失败，请重试';
    }
  }

  private async capture(before: boolean): Promise<void> {
    try {
      const host: Context | undefined = this.getUIContext().getHostContext();
      if (host === undefined) { throw new Error('无法打开相机'); }
      const profile: cameraPicker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
      };
      const result: cameraPicker.PickerResult = await cameraPicker.pick(host,
        [cameraPicker.PickerMediaType.PHOTO], profile);
      if (result.resultCode === 0 && result.resultUri.length > 0) {
        if (before) { this.beforeUri = result.resultUri; }
        else { this.afterUri = result.resultUri; }
      }
    } catch (error) {
      this.hint = '拍照失败，请重试或从相册选择';
    }
  }

  private submit(): void {
    if (this.beforeUri.length === 0 || this.afterUri.length === 0) {
      this.hint = '请先选择开工前和完工后的照片';
      return;
    }
    this.getUIContext().showAlertDialog({
      title: '照片审批接口待接入',
      message: '照片尚未上传。需要服务端保存照片、生成待审批记录并通知其他成员。',
      confirm: { value: '知道了', action: () => {} }
    });
  }

  @Builder
  photoCard(title: string, uri: string, before: boolean) {
    Column({ space: 10 }) {
      Text(title).fontSize(17).fontWeight(FontWeight.Bold).fontColor('#30363A')
        .width('100%')
      if (uri.length > 0) {
        Image(uri).width('100%').height(165).objectFit(ImageFit.Cover)
          .borderRadius(12)
      } else {
        Column({ space: 8 }) {
          Image($r('app.media.hf_task_sweeping')).width(59).height(59)
          Text('尚未选择照片').fontSize(13).fontColor('#798780')
        }.width('100%').height(165).justifyContent(FlexAlign.Center)
          .backgroundColor('#F2F7F0').borderRadius(12)
      }
      Row({ space: 8 }) {
        Button('拍照').layoutWeight(1).height(42)
          .fontColor('#FFFFFF').backgroundColor('#4C9C7C')
          .onClick(() => this.capture(before))
        Button('从相册选择').layoutWeight(1).height(42)
          .fontSize(12).fontColor('#34745D').backgroundColor('#E7F3EA')
          .onClick(() => this.pick(before))
      }.width('100%')
    }.padding(16).width('100%').backgroundColor('#FFFFFF').borderRadius(16)
      .border({ width: 1, color: '#DCE8DF' })
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column({ space: 14 }) {
            Row({ space: 12 }) {
              Image($r('app.media.hf_space_back')).width(38).height(38)
                .onClick(() => this.pageStack.pop())
              Text('完成任务').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
            }.width('100%').margin({ top: 12 })
            Text(this.task === null ? '任务照片' : this.task.title)
              .fontSize(16).fontColor('#34745D').width('100%')
            Text('选择开工前与完工后的照片，请室友确认完成情况。')
              .fontSize(13).fontColor('#798780').width('100%')
            this.photoCard('开工前照片', this.beforeUri, true)
            this.photoCard('完工后照片', this.afterUri, false)
            if (this.hint.length > 0) {
              Text(this.hint).fontSize(12).fontColor('#BF715D').width('100%')
            }
            Text('当前照片只在本机预览，离开页面后不会保存。')
              .fontSize(12).fontColor('#798780').width('100%')
          }.padding({ left: 24, right: 24, top: 5, bottom: 20 }).width('100%')
        }.layoutWeight(1).width('100%')
        Button('提交室友审批').width('100%').height(48)
          .backgroundColor('#4C9C7C').onClick(() => this.submit())
          .margin({ left: 24, right: 24, top: 9, bottom: 9 })
      }.width('100%').height('100%')
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
