@Component
export struct PrivacyPage {
  pageStack: NavPathStack = new NavPathStack();

  @Builder
  privacyCard(icon: Resource, title: string, audience: string, description: string, note: string) {
    Column({ space: 13 }) {
      Row({ space: 12 }) {
        Image(icon).width(44).height(44).objectFit(ImageFit.Contain)
        Text(title).fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor('#30363A').layoutWeight(1)
        Text(audience).fontSize(11).fontColor('#34745D')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#E7F3EA').borderRadius(12)
      }.width('100%')
      Text(description).fontSize(14).fontColor('#30363A').width('100%')
      Text(note).fontSize(12).fontColor('#798780').width('100%')
    }.padding(17).width('100%').backgroundColor('#FFFFFF').borderRadius(16)
      .border({ width: 1, color: '#DCE8DF' }).margin({ bottom: 14 })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Row({ space: 12 }) {
            Image($r('app.media.hf_space_back')).width(38).height(38)
              .onClick(() => this.pageStack.pop())
            Column({ space: 2 }) {
              Text('隐私与数据').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
              Text('了解哪些内容会被谁看到').fontSize(13).fontColor('#798780')
            }.alignItems(HorizontalAlign.Start)
          }.width('100%').margin({ top: 12, bottom: 24 })
          this.privacyCard($r('app.media.hf_privacy_lock'), '私有沟通内容', '仅自己可见',
            '当前输入与本次会话草稿不会自动发送给室友。',
            '未来启用 AI 优化时，内容需由服务端发送给模型服务处理；届时会在发送前明确提示。')
          this.privacyCard($r('app.media.hf_task_sweeping'), '任务前后照片', '计划供空间成员查看',
            '照片上传和审批尚未接入。',
            '启用前将明确照片可见范围、保留期限与删除方式。')
          this.privacyCard($r('app.media.hf_feature_consensus'), '规则与表决', '计划供空间成员查看',
            '提案内容、投票结果和表决记录需要空间成员共享。',
            '当前服务端尚未提供规则与表决接口。')
          Text('管理我的数据').fontSize(19).fontWeight(FontWeight.Bold)
            .fontColor('#30363A').width('100%').margin({ top: 10, bottom: 11 })
          Row({ space: 12 }) {
            Image($r('app.media.hf_tab_communication')).width(42).height(42)
            Column({ space: 4 }) {
              Text('管理本次会话草稿').fontSize(16).fontWeight(FontWeight.Bold)
                .fontColor('#30363A')
              Text('查看、修改或逐条删除').fontSize(12).fontColor('#798780')
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text('›').fontSize(22).fontColor('#34745D')
          }.padding(16).width('100%').backgroundColor('#FFFFFF').borderRadius(15)
            .border({ width: 1, color: '#DCE8DF' })
            .onClick(() => this.pageStack.pushPath({ name: 'Drafts' }))
          Text('退出登录会清除本机登录状态和本次会话草稿。账号与空间中的任务不会因此删除。')
            .fontSize(12).fontColor('#34745D').padding(15).width('100%')
            .backgroundColor('#EFF6EE').borderRadius(12).margin({ top: 21 })
        }.padding({ left: 24, right: 24, top: 5, bottom: 29 }).width('100%')
      }.width('100%').height('100%')
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
