import { HomeFlowSuggestionRouteParam } from '../../api/HomeFlowApi';

@Component
export struct CommunicationPage {
  pageStack: NavPathStack = new NavPathStack();
  @State private concernText: string = '';
  @State private tone: number = 0;
  @State private inputHint: string = '';

  private generate(): void {
    if (this.concernText.trim().length === 0) {
      this.inputHint = '先说说你遇到的事';
      return;
    }
    this.inputHint = '';
    const routeParam: HomeFlowSuggestionRouteParam = { concernText: this.concernText.trim(), tone: this.tone };
    this.pageStack.pushPath({ name: 'Suggestions', param: routeParam });
  }

  @Builder
  toneButton(label: string, number: number) {
    Button(label)
      .layoutWeight(1).height(40)
      .fontSize(13)
      .fontWeight(this.tone === number ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.tone === number ? '#FFFFFF' : '#61776A')
      .backgroundColor(this.tone === number ? '#4C9C7C' : '#FFFFFF')
      .border({ width: this.tone === number ? 0 : 1, color: '#DCE8DF' })
      .borderRadius(12)
      .onClick(() => this.tone = number)
  }

  build() {
    Scroll() {
      Column() {
        Row({ space: 10 }) {
          Image($r('app.media.hf_tab_communication'))
            .width(32).height(32).objectFit(ImageFit.Contain)
          Text('沟通')
            .fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
        }
        .width('100%').margin({ top: 12 })
        Text('先整理想法，再当面好好沟通')
          .fontSize(13).fontColor('#798780')
          .width('100%').margin({ top: 3 })

        Image($r('app.media.hf_communication_bubbles'))
          .width('100%').height(156).objectFit(ImageFit.Contain)
          .margin({ top: 20, bottom: 12 })

        Text('有什么事想好好说？')
          .fontSize(21).fontWeight(FontWeight.Bold).fontColor('#30363A')
          .width('100%').margin({ bottom: 12 })
        Column() {
          Row() {
            Text('')
              .layoutWeight(1)
            Text('清空')
              .fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor(this.concernText.length === 0 ? '#B6C8B9' : '#34745D')
              .onClick(() => this.concernText = '')
          }
          .width('100%')
          TextArea({
            placeholder: '例如：夜里游戏声音有点大，\n我想和室友商量一个安静时段……',
            text: this.concernText
          })
            .maxLength(500)
            .fontSize(14).fontColor('#30363A')
            .placeholderColor('#8FA298')
            .width('100%').height(92)
            .backgroundColor('#FFFFFF')
            .onChange((value: string) => {
              this.concernText = value;
              this.inputHint = '';
            })
          Text(this.concernText.length.toString() + ' / 500')
            .fontSize(12).fontColor('#9AAD9F')
            .width('100%').textAlign(TextAlign.End)
        }
        .padding(13).width('100%')
        .backgroundColor('#FFFFFF').borderRadius(16)
        .border({ width: 0.8, color: '#DCE8DF' })
        .shadow({ radius: 9, color: '#20536B56', offsetY: 6 })

        if (this.inputHint.length > 0) {
          Text(this.inputHint)
            .fontSize(12).fontColor('#BF715D')
            .width('100%').margin({ top: 5 })
        }

        Text('点击生成后，文字会发送给模型服务处理；不会自动发给室友')
          .fontSize(12).fontColor('#798780')
          .width('100%').margin({ top: 9, bottom: 23 })
        Text('希望怎样表达？')
          .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#30363A')
          .width('100%').margin({ bottom: 12 })
        Row({ space: 10 }) {
          this.toneButton('温柔委婉', 0)
          this.toneButton('轻松友好', 1)
          this.toneButton('清晰直接', 2)
        }
        .width('100%')
        Button('整理表达草稿')
          .width('100%').height(48)
          .fontSize(17).fontWeight(FontWeight.Bold)
          .backgroundColor('#4C9C7C').borderRadius(12)
          .margin({ top: 32 })
          .onClick(() => this.generate())
        Text('先用本地模板整理想法；可预览、编辑，再用自己的话当面沟通')
          .fontSize(12).fontColor('#798780')
          .margin({ top: 12, bottom: 22 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 5, bottom: 15 })
    }
    .width('100%').height('100%')
    .backgroundColor('#FFF9F2')
  }
}
