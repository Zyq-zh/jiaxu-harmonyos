@Component
export struct PreviewPage {
  pageStack: NavPathStack = new NavPathStack();
  @Prop pageTitle: string = '';
  @Prop pageHint: string = '';

  build() {
    NavDestination() {
      Column({ space: 22 }) {
        Row() {
          Image($r('app.media.hf_space_back'))
            .width(42)
            .height(42)
            .onClick(() => this.pageStack.pop())
          Text(this.pageTitle)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#273F35')
            .margin({ left: 14 })
        }
        .width('100%')
        Text(this.pageHint)
          .fontSize(16)
          .fontColor('#60776D')
          .width('100%')
        Button('返回')
          .width('100%')
          .backgroundColor('#4C9C7C')
          .onClick(() => this.pageStack.pop())
      }
      .padding(24)
      .width('100%')
    }
    .hideTitleBar(true)
    .backgroundColor('#FFF9F2')
  }
}
