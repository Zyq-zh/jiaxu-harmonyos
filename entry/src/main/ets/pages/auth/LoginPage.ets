import { HomeFlowApi, HomeFlowSpace } from '../../api/HomeFlowApi';

@Component
export struct LoginPage {
  pageStack: NavPathStack = new NavPathStack();
  @State private accountText: string = '';
  @State private passwordText: string = '';
  @State private passwordVisible: boolean = false;
  @State private formHint: string = '';
  @State private submitting: boolean = false;

  private passwordType(): InputType {
    return this.passwordVisible ? InputType.Normal : InputType.Password;
  }

  private async login(): Promise<void> {
    if (this.submitting) {
      return;
    }
    const account: string = this.accountText.trim().toLowerCase();
    if (account.length < 3 || account.length > 32 || !/^[a-z0-9_]+$/.test(account)) {
      this.formHint = '请输入 3—32 位有效账号';
      return;
    }
    if (this.passwordText.length < 8 || this.passwordText.length > 64) {
      this.formHint = '请输入 8—64 位密码';
      return;
    }
    this.submitting = true;
    try {
      const currentSpace: HomeFlowSpace | null = await HomeFlowApi.login(account, this.passwordText);
      this.formHint = '';
      this.passwordText = '';
      this.passwordVisible = false;
      this.pageStack.pushPath({ name: currentSpace === null ? 'CreateSpace' : 'Main' });
    } catch (error) {
      this.formHint = (error as Error).message;
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Scroll() {
      Column() {
        Row({ space: 10 }) {
          Image($r('app.media.hf_login_brand'))
            .width(32).height(32).objectFit(ImageFit.Contain)
          Column({ space: 0 }) {
            Text('家序 HomeFlow')
              .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#30363A')
            Text('让共同生活更轻松')
              .fontSize(12).fontColor('#798780')
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .margin({ top: 14 })

        Image($r('app.media.hf_login_hero'))
          .width('100%').height(184).objectFit(ImageFit.Contain)
          .margin({ top: 14, bottom: 12 })

        Text('欢迎回家')
          .fontSize(30).fontWeight(FontWeight.Bold).fontColor('#30363A')
          .width('100%')
        Text('把家务安排好，也把话说得更温柔。')
          .fontSize(14).fontColor('#798780')
          .width('100%').margin({ top: 5, bottom: 20 })

        Text('账号')
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A')
          .width('100%').margin({ bottom: 7 })
        Row({ space: 8 }) {
          Image($r('app.media.hf_login_user'))
            .width(26).height(26).objectFit(ImageFit.Contain)
          TextInput({ placeholder: '请输入账号', text: this.accountText })
            .maxLength(32)
            .fontSize(15).placeholderColor('#A3AEA6')
            .backgroundColor('#FFFFFF').border({ width: 0 })
            .layoutWeight(1)
            .onChange((value: string) => {
              this.accountText = value;
              this.formHint = '';
            })
        }
        .padding({ left: 10, right: 10 })
        .height(50).width('100%')
        .backgroundColor('#FFFFFF').borderRadius(12)
        .border({ width: 1, color: '#E2E8DF' })

        Text('密码')
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A')
          .width('100%').margin({ top: 13, bottom: 7 })
        Row({ space: 8 }) {
          Image($r('app.media.hf_login_lock'))
            .width(26).height(26).objectFit(ImageFit.Contain)
          TextInput({ placeholder: '请输入密码', text: this.passwordText })
            .type(this.passwordType()).showPasswordIcon(false)
            .maxLength(64)
            .fontSize(15).placeholderColor('#A3AEA6')
            .backgroundColor('#FFFFFF').border({ width: 0 })
            .layoutWeight(1)
            .onChange((value: string) => {
              this.passwordText = value;
              this.formHint = '';
            })
          Image(this.passwordVisible ? $r('app.media.hf_login_eye') : $r('app.media.hf_login_eye_off'))
            .width(26).height(26).objectFit(ImageFit.Contain)
            .padding(2)
            .onClick(() => this.passwordVisible = !this.passwordVisible)
        }
        .padding({ left: 10, right: 10 })
        .height(50).width('100%')
        .backgroundColor('#FFFFFF').borderRadius(12)
        .border({ width: 1, color: '#E2E8DF' })

        if (this.formHint.length > 0) {
          Text(this.formHint)
            .fontSize(12).fontColor('#BF715D')
            .width('100%').margin({ top: 5 })
        }

        Button(this.submitting ? '登录中…' : '登录')
          .width('100%').height(50)
          .fontSize(17).fontWeight(FontWeight.Bold)
          .backgroundColor('#4C9C7C').borderRadius(12)
          .enabled(!this.submitting)
          .margin({ top: 24 })
          .onClick(() => this.login())
        Button('注册新账号')
          .width('100%').height(50)
          .fontSize(17).fontWeight(FontWeight.Bold)
          .fontColor('#4C9C7C').backgroundColor('#FFFFFF').borderRadius(12)
          .margin({ top: 10 })
          .onClick(() => this.pageStack.pushPath({ name: 'Register' }))

        Column({ space: 2 }) {
          Text('登录即表示同意')
            .fontSize(12).fontColor('#798780')
          Text('《隐私说明》')
            .fontSize(13).fontWeight(FontWeight.Bold).fontColor('#4C9C7C')
            .onClick(() => this.pageStack.pushPath({ name: 'Privacy' }))
        }
        .width('100%')
        .margin({ top: 26, bottom: 18 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 10, bottom: 14 })
    }
    .width('100%').height('100%')
    .backgroundColor('#FFF9F2')
  }
}
