import { HomePage } from './HomePage';
import { SchedulePage } from './SchedulePage';
import { CommunicationPage } from './CommunicationPage';
import { SettingsPage } from './SettingsPage';
import { HomeFlowApi, HomeFlowTaskInput } from '../../api/HomeFlowApi';

@Component
export struct MainShellPage {
  pageStack: NavPathStack = new NavPathStack();
  @State private selectedTab: number = 0;
  @State private showTaskSheet: boolean = false;
  @State private taskNameText: string = '';
  @State private taskHint: string = '';
  @State private selectedCategory: number = 0;
  @State private difficulty: number = 1;
  @State private responsible: number = 0;
  @State private taskDateMillis: number = Date.now();
  @State private taskHour: number = new Date().getHours();
  @State private taskMinute: number = new Date().getMinutes();
  @State private durationIndex: number = 3;
  @State private submittingTask: boolean = false;
  @State private taskRevision: number = 0;

  private openTaskSheet(date: Date): void {
    const now: Date = new Date();
    const suggested: Date = new Date(now.getTime() + 30 * 60 * 1000);
    const target: Date = date.getTime() < now.getTime() ? suggested : date;
    this.taskDateMillis = target.getTime();
    this.taskHour = target.toDateString() === now.toDateString() ? suggested.getHours() : 21;
    this.taskMinute = target.toDateString() === now.toDateString() ? suggested.getMinutes() : 0;
    this.taskHint = '';
    this.showTaskSheet = true;
  }

  private async submitTask(): Promise<void> {
    if (this.submittingTask) {
      return;
    }
    if (this.taskNameText.trim().length === 0 || this.taskNameText.trim().length > 60) {
      this.taskHint = '任务名称需为 1—60 个字';
      return;
    }
    const selected: Date = new Date(this.taskDateMillis);
    selected.setHours(this.taskHour, this.taskMinute, 0, 0);
    if (selected.getTime() <= Date.now()) {
      this.taskHint = '截止时间须晚于当前时间';
      return;
    }
    const today: Date = new Date();
    if (this.responsible === 1 && selected.toDateString() === today.toDateString()) {
      this.taskHint = '今天的任务请选择我负责';
      return;
    }
    const categories: string[] = ['floor', 'trash', 'dishes', 'bathroom', 'laundry',
      'supplies', 'plants', 'organizing', 'surfaces', 'other'];
    const durations: number[] = [10, 15, 20, 25, 30, 45, 60, 90, 120];
    const difficulties: string[] = ['easy', 'medium', 'hard'];
    const dateText: string = selected.getFullYear().toString() + '-' +
      this.twoDigits(selected.getMonth() + 1) + '-' + this.twoDigits(selected.getDate());
    const taskInput: HomeFlowTaskInput = {
      title: this.taskNameText.trim(),
      category: categories[this.selectedCategory],
      executionDate: dateText,
      deadlineAt: selected.toISOString(),
      estimatedMinutes: durations[this.durationIndex],
      difficulty: difficulties[this.difficulty],
      assignmentMode: this.responsible === 0 ? 'self' : 'fair'
    };
    this.submittingTask = true;
    try {
      await HomeFlowApi.createTask(taskInput);
      this.showTaskSheet = false;
      this.taskNameText = '';
      this.taskRevision += 1;
      this.getUIContext().showAlertDialog({
        title: '任务创建成功',
        message: '可在日程中查看这项任务。',
        confirm: { value: '知道了', action: () => {} }
      });
    } catch (error) {
      this.taskHint = (error as Error).message;
    } finally {
      this.submittingTask = false;
    }
  }

  private twoDigits(value: number): string {
    return value < 10 ? '0' + value.toString() : value.toString();
  }

  private taskDateLabel(): string {
    const selected: Date = new Date(this.taskDateMillis);
    const today: Date = new Date();
    if (selected.getFullYear() === today.getFullYear() &&
      selected.getMonth() === today.getMonth() &&
      selected.getDate() === today.getDate()) {
      return '今天';
    }
    return selected.getFullYear().toString() + ' 年 ' +
      (selected.getMonth() + 1).toString() + ' 月 ' + selected.getDate().toString() + ' 日';
  }

  private taskTimeLabel(): string {
    return this.twoDigits(this.taskHour) + ':' + this.twoDigits(this.taskMinute);
  }

  private chooseDate(): void {
    this.getUIContext().showDatePickerDialog({
      selected: new Date(this.taskDateMillis),
      start: new Date(),
      onDateAccept: (value: Date) => {
        this.taskDateMillis = value.getTime();
      }
    });
  }

  private chooseTime(): void {
    const selected: Date = new Date(this.taskDateMillis);
    selected.setHours(this.taskHour, this.taskMinute, 0, 0);
    this.getUIContext().showTimePickerDialog({
      selected: selected,
      useMilitaryTime: true,
      onAccept: (value: TimePickerResult) => {
        this.taskHour = value.hour;
        this.taskMinute = value.minute;
      }
    });
  }

  private chooseDuration(): void {
    this.getUIContext().showTextPickerDialog({
      range: ['10 分钟', '15 分钟', '20 分钟', '25 分钟', '30 分钟', '45 分钟', '60 分钟', '90 分钟', '120 分钟'],
      selected: this.durationIndex,
      onAccept: (value: TextPickerResult) => {
        this.durationIndex = Array.isArray(value.index) ? value.index[0] : value.index;
      }
    });
  }

  private chooseDifficulty(): void {
    this.getUIContext().showTextPickerDialog({
      range: ['简单', '中等', '较难'],
      selected: this.difficulty,
      onAccept: (value: TextPickerResult) => {
        this.difficulty = Array.isArray(value.index) ? value.index[0] : value.index;
      }
    });
  }

  private durationLabel(): string {
    const values: string[] = ['10 分钟', '15 分钟', '20 分钟', '25 分钟', '30 分钟',
      '45 分钟', '60 分钟', '90 分钟', '120 分钟'];
    return values[this.durationIndex];
  }

  private difficultyLabel(): string {
    const values: string[] = ['简单', '中等', '较难'];
    return values[this.difficulty];
  }

  @Builder
  categoryButton(icon: Resource, label: string, number: number) {
    Column({ space: 4 }) {
      Image(icon).width(32).height(32).objectFit(ImageFit.Contain)
      Text(label)
        .fontSize(11).fontWeight(this.selectedCategory === number ? FontWeight.Bold : FontWeight.Normal)
        .fontColor('#34745D')
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1).height(73)
    .backgroundColor(this.selectedCategory === number ? '#E7F3EA' : '#FFFFFF')
    .border({ width: 1, color: this.selectedCategory === number ? '#4C9C7C' : '#DCE8DF' })
    .borderRadius(12)
    .onClick(() => this.selectedCategory = number)
  }

  @Builder
  taskSheetContent() {
    Scroll() {
      Column() {
        Row() {
          Text('新建任务')
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#30363A')
            .layoutWeight(1)
          Text('取消')
            .fontSize(14).fontColor('#798780')
            .onClick(() => this.showTaskSheet = false)
        }
        .width('100%')
        Text('任务创建后可加入下一次公平排班')
          .fontSize(13).fontColor('#798780')
          .width('100%').margin({ top: 4, bottom: 18 })

        Text('任务名称')
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A')
          .width('100%').margin({ bottom: 7 })
        TextInput({ placeholder: '例如：整理鞋架', text: this.taskNameText })
          .maxLength(60)
          .height(45).width('100%')
          .backgroundColor('#FFFFFF').borderRadius(11)
          .border({ width: 1, color: '#DCE8DF' })
          .onChange((value: string) => {
            this.taskNameText = value;
            this.taskHint = '';
          })
        if (this.taskHint.length > 0) {
          Text(this.taskHint)
            .fontSize(12).fontColor('#BF715D')
            .width('100%').margin({ top: 4 })
        }

        Text('家务分类')
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A')
          .width('100%').margin({ top: 19, bottom: 8 })
        Row({ space: 7 }) {
          this.categoryButton($r('app.media.hf_task_sweeping'), '扫地', 0)
          this.categoryButton($r('app.media.hf_task_trash'), '倒垃圾', 1)
          this.categoryButton($r('app.media.hf_task_dishes'), '洗碗', 2)
          this.categoryButton($r('app.media.hf_task_bathroom'), '卫生间', 3)
        }
        .width('100%')
        Row({ space: 7 }) {
          this.categoryButton($r('app.media.hf_task_laundry'), '洗衣', 4)
          this.categoryButton($r('app.media.hf_task_supplies'), '采购', 5)
          this.categoryButton($r('app.media.hf_task_plants'), '植物', 6)
          this.categoryButton($r('app.media.hf_task_organizing'), '收纳', 7)
        }
        .width('100%').margin({ top: 7 })
        Row({ space: 7 }) {
          this.categoryButton($r('app.media.hf_task_surfaces'), '擦桌', 8)
          this.categoryButton($r('app.media.hf_task_other'), '其他', 9)
          Blank().layoutWeight(1)
          Blank().layoutWeight(1)
        }
        .width('100%').margin({ top: 7 })

        Text('执行日期与截止')
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A')
          .width('100%').margin({ top: 17, bottom: 7 })
        Row({ space: 8 }) {
          Text(this.taskDateLabel() + '  ›')
            .fontSize(14).fontColor('#30363A')
            .layoutWeight(1).height(45)
            .padding({ left: 12, top: 12 })
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#DCE8DF' }).borderRadius(11)
            .onClick(() => this.chooseDate())
          Text(this.taskTimeLabel() + '  ›')
            .fontSize(14).fontColor('#30363A')
            .width(100).height(45)
            .padding({ left: 12, top: 12 })
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#DCE8DF' }).borderRadius(11)
            .onClick(() => this.chooseTime())
        }
        .width('100%')

        Row({ space: 10 }) {
          Column({ space: 7 }) {
            Text('预计用时')
              .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A')
            Text(this.durationLabel() + '  ›')
              .fontSize(15).fontColor('#30363A')
              .width('100%').height(45).padding({ left: 12, top: 12 })
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#DCE8DF' }).borderRadius(11)
              .onClick(() => this.chooseDuration())
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
          Column({ space: 7 }) {
            Text('难度')
              .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A')
            Text(this.difficultyLabel() + '  ›')
              .fontSize(15).fontColor('#30363A')
              .width('100%').height(45).padding({ left: 12, top: 12 })
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#DCE8DF' }).borderRadius(11)
              .onClick(() => this.chooseDifficulty())
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
        }
        .width('100%').margin({ top: 17 })

        Text('责任人')
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A')
          .width('100%').margin({ top: 18, bottom: 7 })
        Row({ space: 10 }) {
          Button('我负责')
            .layoutWeight(1).height(43)
            .fontSize(14).fontWeight(FontWeight.Bold)
            .fontColor('#34745D')
            .backgroundColor(this.responsible === 0 ? '#E7F3EA' : '#FFFFFF')
            .border({ width: 1, color: this.responsible === 0 ? '#4C9C7C' : '#DCE8DF' })
            .borderRadius(11)
            .onClick(() => this.responsible = 0)
          Button('交给公平排班')
            .layoutWeight(1).height(43)
            .fontSize(14).fontWeight(FontWeight.Bold)
            .fontColor('#34745D')
            .backgroundColor(this.responsible === 1 ? '#E7F3EA' : '#FFFFFF')
            .border({ width: 1, color: this.responsible === 1 ? '#4C9C7C' : '#DCE8DF' })
            .borderRadius(11)
            .onClick(() => this.responsible = 1)
        }
        .width('100%')
        Text('今天的临时任务先指定责任人；未来任务可交给排班')
          .fontSize(12).fontColor('#798780')
          .width('100%').margin({ top: 10, bottom: 22 })
        Button(this.submittingTask ? '创建中…' : '创建任务')
          .width('100%').height(48)
          .fontSize(16).fontWeight(FontWeight.Bold)
          .backgroundColor('#4C9C7C').borderRadius(12)
          .enabled(!this.submittingTask)
          .onClick(() => this.submitTask())
      }
      .padding(24).width('100%')
    }
    .width('100%').height('100%')
    .backgroundColor('#FFF9F2')
  }

  @Builder
  tab(icon: Resource, label: string, tabNumber: number) {
    Column({ space: 2 }) {
      Image(icon)
        .width(27).height(27).objectFit(ImageFit.Contain)
      Text(label)
        .fontSize(11)
        .fontWeight(this.selectedTab === tabNumber ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.selectedTab === tabNumber ? '#34745D' : '#798780')
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1).height(55)
    .backgroundColor(this.selectedTab === tabNumber ? '#E7F3EA' : '#FFFFFF')
    .borderRadius(13)
    .onClick(() => {
      this.selectedTab = tabNumber;
      if (tabNumber === 0 || tabNumber === 1) {
        this.taskRevision += 1;
      }
    })
  }

  build() {
    NavDestination() {
      Column() {
        if (this.selectedTab === 0) {
          HomePage({ pageStack: this.pageStack, taskRevision: this.taskRevision,
            onCreateTask: () => this.openTaskSheet(new Date()) })
            .layoutWeight(1)
        } else if (this.selectedTab === 1) {
          SchedulePage({ pageStack: this.pageStack, taskRevision: this.taskRevision,
            onCreateTask: (date: Date) => this.openTaskSheet(date) })
            .layoutWeight(1)
        } else if (this.selectedTab === 2) {
          CommunicationPage({ pageStack: this.pageStack })
            .layoutWeight(1)
        } else {
          SettingsPage({ pageStack: this.pageStack })
            .layoutWeight(1)
        }
        Row({ space: 4 }) {
          this.tab($r('app.media.hf_tab_home'), '首页', 0)
          this.tab($r('app.media.hf_tab_schedule'), '日程', 1)
          this.tab($r('app.media.hf_tab_communication'), '沟通', 2)
          this.tab($r('app.media.hf_tab_settings'), '个人设置', 3)
        }
        .padding({ left: 24, right: 24, top: 5, bottom: 3 })
        .height(64).width('100%')
        .backgroundColor('#FFFFFF')
        .border({ width: 0.5, color: '#DDE9DF' })
      }
      .width('100%').height('100%')
      .backgroundColor('#FFF9F2')
      .bindSheet($$this.showTaskSheet, this.taskSheetContent, {
        height: SheetSize.LARGE, dragBar: false, showClose: false, backgroundColor: '#FFFFFF'
      })
    }
    .hideTitleBar(true)
    .backgroundColor('#FFF9F2')
  }
}
