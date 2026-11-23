import { HomeFlowApi } from '../../api/HomeFlowApi';

@Component
export struct RegisterPage {
  pageStack: NavPathStack = new NavPathStack();
  @State private accountText: string = '';
  @State private passwordText: string = '';
  @State private confirmText: string = '';
  @State private nicknameText: string = '';
  @State private validationHint: string = '';
  @State private submitting: boolean = false;

  private async submitRegister(): Promise<void> {
    if (this.submitting) {
      return;
    }
    const account: string = this.accountText.trim().toLowerCase();
    if (account.length < 3 || account.length > 32 || !/^[a-z0-9_]+$/.test(account)) {
      this.validationHint = '账号需为 3—32 位小写字母、数字或下划线';
      return;
    }
    if (this.passwordText.length < 8 || this.passwordText.length > 64 ||
      !/[A-Za-z]/.test(this.passwordText) || !/[0-9]/.test(this.passwordText) ||
      /\s/.test(this.passwordText)) {
      this.validationHint = '密码需为 8—64 位，包含字母和数字，不能有空白字符';
      return;
    }
    if (this.passwordText !== this.confirmText) {
      this.validationHint = '两次输入的密码不一致';
      return;
    }
    if (this.nicknameText.trim().length < 2 || this.nicknameText.trim().length > 12) {
      this.validationHint = '昵称需为 2—12 个字';
      return;
    }
    this.submitting = true;
    try {
      await HomeFlowApi.register(account, this.passwordText, this.nicknameText.trim());
      this.validationHint = '';
      this.getUIContext().showAlertDialog({
        title: '注册成功',
        message: '请返回登录页面，使用新账号登录。',
        confirm: { value: '返回登录', action: () => this.pageStack.pop() }
      });
    } catch (error) {
      this.validationHint = (error as Error).message;
    } finally {
      this.submitting = false;
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          Row() {
            Image($r('app.media.hf_space_back'))
              .width(42)
              .height(42)
              .onClick(() => this.pageStack.pop())
            Text('注册账号')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#273F35')
              .margin({ left: 14 })
          }
          .width('100%')

          Text('创建家序账号')
            .fontSize(17)
            .fontColor('#60776D')
            .width('100%')
            .margin({ top: 20 })

          TextInput({ placeholder: '账号（3—32 位字母、数字或下划线）', text: this.accountText })
            .maxLength(32)
            .height(52)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .onChange((inputText: string) => this.accountText = inputText)

          TextInput({ placeholder: '昵称（2—12 字）', text: this.nicknameText })
            .maxLength(12)
            .height(52)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .onChange((inputText: string) => this.nicknameText = inputText)

          TextInput({ placeholder: '密码（8—64 位，含字母和数字）', text: this.passwordText })
            .type(InputType.Password)
            .maxLength(64)
            .height(52)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .onChange((inputText: string) => this.passwordText = inputText)

          TextInput({ placeholder: '确认密码', text: this.confirmText })
            .type(InputType.Password)
            .maxLength(64)
            .height(52)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .onChange((inputText: string) => this.confirmText = inputText)

          if (this.validationHint.length > 0) {
            Text(this.validationHint)
              .fontSize(13)
              .fontColor('#B65B4B')
              .width('100%')
          }

          Button(this.submitting ? '注册中…' : '注册')
            .width('100%')
            .backgroundColor('#4C9C7C')
            .enabled(!this.submitting)
            .onClick(() => this.submitRegister())
        }
        .padding(24)
        .width('100%')
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor('#FFF9F2')
  }
}
