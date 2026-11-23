import { HomeFlowApi, HomeFlowTask, HomeFlowTaskRouteParam } from '../../api/HomeFlowApi';

@Component
export struct SchedulePage {
  pageStack: NavPathStack = new NavPathStack();
  onCreateTask: (date: Date) => void = (date: Date) => {};
  @Prop @Watch('onRevisionChanged') taskRevision: number = 0;
  @StorageLink('homeflowTaskRevision') @Watch('onRevisionChanged') private sharedTaskRevision: number = 0;
  @State private monthOffset: number = 0;
  @State private selectedDay: number = new Date().getDate();
  @State private monthTasks: HomeFlowTask[] = [];
  @State private loadHint: string = '';

  aboutToAppear(): void {
    this.monthOffset = 0;
    this.selectedDay = new Date().getDate();
    this.loadTasks();
  }

  private onRevisionChanged(): void {
    this.loadTasks();
  }

  private dateKey(date: Date): string {
    const month: string = (date.getMonth() + 1).toString().padStart(2, '0');
    const day: string = date.getDate().toString().padStart(2, '0');
    return date.getFullYear().toString() + '-' + month + '-' + day;
  }

  private async loadTasks(): Promise<void> {
    const month: Date = this.displayMonth();
    const last: Date = new Date(month.getFullYear(), month.getMonth() + 1, 0);
    try {
      this.monthTasks = await HomeFlowApi.tasks(this.dateKey(month), this.dateKey(last));
      this.loadHint = '';
    } catch (error) {
      this.monthTasks = [];
      this.loadHint = (error as Error).message;
    }
  }

  private selectedDayTasks(): HomeFlowTask[] {
    const key: string = this.dateKey(this.selectedDate());
    return this.monthTasks.filter((task: HomeFlowTask): boolean => task.executionDate === key);
  }

  private selectedDate(): Date {
    const month: Date = this.displayMonth();
    return new Date(month.getFullYear(), month.getMonth(), this.selectedDay);
  }

  private changeMonth(delta: number): void {
    const next: Date = this.displayMonth();
    next.setMonth(next.getMonth() + delta);
    const lastDay: number = new Date(next.getFullYear(), next.getMonth() + 1, 0).getDate();
    this.selectedDay = Math.min(this.selectedDay, lastDay);
    this.monthOffset += delta;
    this.loadTasks();
  }

  private selectedHasTask(): boolean {
    return this.selectedDayTasks().length > 0;
  }

  private displayMonth(): Date {
    const value: Date = new Date();
    value.setDate(1);
    value.setMonth(value.getMonth() + this.monthOffset);
    return value;
  }

  private monthLabel(): string {
    const value: Date = this.displayMonth();
    return value.getFullYear().toString() + ' 年 ' + (value.getMonth() + 1).toString() + ' 月';
  }

  private cellDate(index: number): Date {
    const first: Date = this.displayMonth();
    const startOffset: number = (first.getDay() + 6) % 7;
    return new Date(first.getFullYear(), first.getMonth(), index - startOffset + 1);
  }

  private isInMonth(index: number): boolean {
    return this.cellDate(index).getMonth() === this.displayMonth().getMonth();
  }

  private isSelected(index: number): boolean {
    return this.isInMonth(index) && this.cellDate(index).getDate() === this.selectedDay;
  }

  private hasTask(index: number): boolean {
    if (!this.isInMonth(index)) {
      return false;
    }
    const key: string = this.dateKey(this.cellDate(index));
    return this.monthTasks.some((task: HomeFlowTask): boolean => task.executionDate === key);
  }

  private selectCell(index: number): void {
    const date: Date = this.cellDate(index);
    const month: Date = this.displayMonth();
    const dateMonth: number = date.getFullYear() * 12 + date.getMonth();
    const currentMonth: number = month.getFullYear() * 12 + month.getMonth();
    this.monthOffset += dateMonth - currentMonth;
    this.selectedDay = date.getDate();
    if (dateMonth !== currentMonth) {
      this.loadTasks();
    }
  }

  private selectedLabel(): string {
    const date: Date = this.displayMonth();
    date.setDate(this.selectedDay);
    const weekdays: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return (date.getMonth() + 1).toString() + ' 月 ' + date.getDate().toString() + ' 日 · ' + weekdays[date.getDay()];
  }

  @Builder
  weekRow(week: number) {
    Row() {
      ForEach([0, 1, 2, 3, 4, 5, 6], (dayIndex: number) => {
        Column({ space: 1 }) {
          Text(this.cellDate(week * 7 + dayIndex).getDate().toString())
            .fontSize(14)
            .fontWeight(this.isSelected(week * 7 + dayIndex) ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.isSelected(week * 7 + dayIndex) ? '#FFFFFF' :
              (this.isInMonth(week * 7 + dayIndex) ? '#30363A' : '#B6C8B9'))
          if (this.hasTask(week * 7 + dayIndex)) {
            Row({ space: 2 }) {
              Column() {}
                .width(4).height(4)
                .backgroundColor(this.isSelected(week * 7 + dayIndex) ? '#FFFFFF' : '#4C9C7C')
                .borderRadius(2)
              if (this.isSelected(week * 7 + dayIndex)) {
                Column() {}
                  .width(4).height(4)
                  .backgroundColor(this.isSelected(week * 7 + dayIndex) ? '#FFFFFF' : '#4C9C7C')
                  .borderRadius(2)
              }
            }
          }
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1).height(34)
        .backgroundColor(this.isSelected(week * 7 + dayIndex) ? '#4C9C7C' : '#FFFFFF')
        .borderRadius(10)
        .onClick(() => this.selectCell(week * 7 + dayIndex))
      }, (dayIndex: number) => this.monthLabel() + '-' + week.toString() + '-' + dayIndex.toString())
    }
    .width('100%')
  }

  @Builder
  taskRow(task: HomeFlowTask) {
    Row({ space: 12 }) {
      Image(this.taskIcon(task.category))
        .width(43).height(43).objectFit(ImageFit.Contain)
        .padding(4).backgroundColor('#F0F5EC').borderRadius(12)
      Column({ space: 4 }) {
        Text(task.title)
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#30363A')
        Text(this.deadlineLabel(task.deadlineAt) + ' 前 · ' + this.statusLabel(task.status))
          .fontSize(12).fontColor('#798780')
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text('›').fontSize(24).fontColor('#798780')
    }
    .width('100%').height(62)
    .onClick(() => {
      const routeParam: HomeFlowTaskRouteParam = { taskId: task.id };
      this.pageStack.pushPath({ name: 'TaskDetail', param: routeParam });
    })
  }

  private statusLabel(taskStatus: string): string {
    if (taskStatus === 'unassigned') { return '待分配'; }
    if (taskStatus === 'todo') { return '待完成'; }
    if (taskStatus === 'cancelled') { return '已取消'; }
    if (taskStatus === 'completed') { return '已完成'; }
    return '进行中';
  }

  private deadlineLabel(deadlineAt: string): string {
    const date: Date = new Date(deadlineAt);
    return date.getHours().toString().padStart(2, '0') + ':' +
      date.getMinutes().toString().padStart(2, '0');
  }

  private taskIcon(category: string): Resource {
    if (category === 'trash') { return $r('app.media.hf_task_trash'); }
    if (category === 'dishes') { return $r('app.media.hf_task_dishes'); }
    if (category === 'bathroom') { return $r('app.media.hf_task_bathroom'); }
    if (category === 'laundry') { return $r('app.media.hf_task_laundry'); }
    if (category === 'supplies') { return $r('app.media.hf_task_supplies'); }
    if (category === 'plants') { return $r('app.media.hf_task_plants'); }
    if (category === 'organizing') { return $r('app.media.hf_task_organizing'); }
    if (category === 'surfaces') { return $r('app.media.hf_task_surfaces'); }
    if (category === 'other') { return $r('app.media.hf_task_other'); }
    return $r('app.media.hf_task_sweeping');
  }

  build() {
    Scroll() {
      Column() {
        Row({ space: 9 }) {
          Image($r('app.media.hf_tab_schedule'))
            .width(33).height(33).objectFit(ImageFit.Contain)
          Text('日程')
            .fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
            .layoutWeight(1)
          Button() {
            Row({ space: 5 }) {
              Image($r('app.media.hf_feature_schedule'))
                .width(23).height(23).objectFit(ImageFit.Contain)
              Text('公平排班')
                .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#34745D')
            }
          }
          .height(37)
          .backgroundColor('#E7F3EA').borderRadius(12)
          .onClick(() => this.pageStack.pushPath({ name: 'FairSchedule' }))
        }
        .width('100%').margin({ top: 12, bottom: 18 })

        Column() {
          Row({ space: 10 }) {
            Text(this.monthLabel())
              .fontSize(19).fontWeight(FontWeight.Bold).fontColor('#30363A')
              .layoutWeight(1)
            Button('今天')
              .height(32).fontSize(13).fontWeight(FontWeight.Bold)
              .fontColor('#34745D').backgroundColor('#E7F3EA')
              .onClick(() => {
                this.monthOffset = 0;
                this.selectedDay = new Date().getDate();
                this.loadTasks();
              })
            Image($r('app.media.hf_space_back'))
              .width(26).height(26).objectFit(ImageFit.Contain)
              .onClick(() => this.changeMonth(-1))
            Image($r('app.media.hf_space_back'))
              .width(26).height(26).objectFit(ImageFit.Contain)
              .rotate({ angle: 180 })
              .onClick(() => this.changeMonth(1))
          }
          .width('100%')
          Divider().strokeWidth(1).color('#E2EAE3').margin({ top: 12, bottom: 10 })
          Row() {
            ForEach(['一', '二', '三', '四', '五', '六', '日'], (label: string) => {
              Text(label)
                .fontSize(12).fontWeight(FontWeight.Bold).fontColor('#798780')
                .layoutWeight(1).textAlign(TextAlign.Center)
            }, (label: string) => label)
          }
          .width('100%').margin({ bottom: 5 })
          this.weekRow(0)
          this.weekRow(1)
          this.weekRow(2)
          this.weekRow(3)
          this.weekRow(4)
          this.weekRow(5)
        }
        .padding(16).width('100%')
        .backgroundColor('#FFFFFF').borderRadius(18)
        .border({ width: 0.8, color: '#DFEAE2' })
        .shadow({ radius: 10, color: '#20536B56', offsetY: 7 })

        Row() {
          Column({ space: 2 }) {
            Text(this.selectedLabel())
              .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#30363A')
            Text(this.selectedDayTasks().length.toString() + ' 项任务')
              .fontSize(13).fontColor('#798780')
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
          Button() {
            Row({ space: 5 }) {
              Image($r('app.media.hf_space_create'))
                .width(22).height(22).objectFit(ImageFit.Contain)
              Text('新建任务')
                .fontSize(13).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
            }
          }
          .width(115).height(40)
          .backgroundColor('#4C9C7C').borderRadius(12)
          .onClick(() => this.onCreateTask(this.selectedDate()))
        }
        .width('100%').margin({ top: 28, bottom: 13 })

        Column() {
          if (this.loadHint.length > 0) {
            Text(this.loadHint).fontSize(13).fontColor('#BF715D')
          }
          if (this.selectedHasTask()) {
            ForEach(this.selectedDayTasks(), (task: HomeFlowTask) => {
              this.taskRow(task)
              Divider().strokeWidth(1).color('#E4EBE5')
            }, (task: HomeFlowTask): string => task.id)
          } else {
            Text('这天还没有安排')
              .fontSize(14).fontColor('#798780')
              .width('100%').textAlign(TextAlign.Center)
              .padding(25)
          }
        }
        .padding({ left: 13, right: 13, top: 5, bottom: 5 })
        .width('100%')
        .backgroundColor('#FFFFFF').borderRadius(16)
        .border({ width: 0.8, color: '#DFEAE2' })
        .shadow({ radius: 8, color: '#18536B56', offsetY: 5 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 5, bottom: 25 })
    }
    .width('100%').height('100%')
    .backgroundColor('#FFF9F2')
  }
}
