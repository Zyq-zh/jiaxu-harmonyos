import { HomeFlowApi, HomeFlowMember, HomeFlowTask } from '../../api/HomeFlowApi';
import { HomeFlowV03, V03Availability, V03Schedule, V03Slot, V03Assignment, V03Conflict } from '../../api/HomeFlowV03';

interface V03FairEditableSlot { slotId: string; date: string; startTime: string; endTime: string; }

@Component
export struct FairSchedulePage {
  pageStack: NavPathStack = new NavPathStack();
  @State private weekOffset: number = 0;
  @State private taskList: HomeFlowTask[] = [];
  @State private memberList: HomeFlowMember[] = [];
  @State private editedSlots: V03FairEditableSlot[] = [];
  @State private selectedDay: number = 0;
  @State private availabilityHint: string = '';
  @State private maxMinutes: string = '180';
  @State private showAvailability: boolean = false;
  @State private hint: string = '';
  @State private availabilityVersion: number = 0;
  @State private currentSchedule: V03Schedule | null = null;
  @State private busy: boolean = false;
  @StorageLink('homeflowTaskRevision') @Watch('onTaskChanged') private sharedTaskRevision: number = 0;

  aboutToAppear(): void { this.loadWeek(); }

  private onTaskChanged(): void { this.loadWeek(); }

  private monday(): Date {
    const today: Date = new Date();
    return new Date(today.getFullYear(), today.getMonth(),
      today.getDate() - (today.getDay() + 6) % 7 + this.weekOffset * 7);
  }

  private sunday(): Date {
    const monday: Date = this.monday();
    return new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 6);
  }

  private dateKey(date: Date): string {
    return date.getFullYear().toString() + '-' +
      (date.getMonth() + 1).toString().padStart(2, '0') + '-' +
      date.getDate().toString().padStart(2, '0');
  }

  private weekLabel(): string {
    const start: Date = this.monday();
    const end: Date = this.sunday();
    return (start.getMonth() + 1).toString() + ' 月 ' + start.getDate().toString() + ' 日 — ' +
      (end.getMonth() + 1).toString() + ' 月 ' + end.getDate().toString() + ' 日';
  }

  private async loadWeek(): Promise<void> {
    try {
      this.taskList = await HomeFlowApi.tasks(this.dateKey(this.monday()), this.dateKey(this.sunday()));
      this.memberList = await HomeFlowApi.members();
      const availability: V03Availability = await HomeFlowV03.availability(this.dateKey(this.monday()));
      this.availabilityVersion = availability.version;
      this.maxMinutes = availability.maxWeekMinutes.toString();
      this.editedSlots = availability.slots.map((slot: V03Slot): V03FairEditableSlot => {
        return { slotId: HomeFlowV03.newKey(), date: slot.date,
          startTime: slot.startTime.substring(0, 5), endTime: slot.endTime.substring(0, 5) };
      });
      this.currentSchedule = await HomeFlowV03.schedule(this.dateKey(this.monday()));
      this.hint = '';
    } catch (error) {
      this.hint = (error as Error).message;
    }
  }

  private changeWeek(delta: number): void {
    this.weekOffset += delta;
    this.loadWeek();
  }

  private unassigned(): HomeFlowTask[] {
    return this.taskList.filter((task: HomeFlowTask): boolean => task.status === 'unassigned');
  }

  private weekDates(): string[] {
    const dates: string[] = [];
    const start: Date = this.monday();
    for (let day: number = 0; day < 7; day += 1) {
      const date: Date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + day);
      dates.push(this.dateKey(date));
    }
    return dates;
  }

  private visibleSlots(): V03FairEditableSlot[] {
    const date: string = this.weekDates()[this.selectedDay];
    return this.editedSlots.filter((slot: V03FairEditableSlot): boolean => slot.date === date);
  }

  private addSlot(): void {
    if (this.editedSlots.length >= 42) {
      this.availabilityHint = '每周最多 42 个时段'; return;
    }
    const date: string = this.weekDates()[this.selectedDay];
    const count: number = this.visibleSlots().length;
    const startHour: number = Math.min(22, 9 + count * 2);
    const endHour: number = startHour + 1;
    const next: V03FairEditableSlot = { slotId: HomeFlowV03.newKey(), date: date,
      startTime: startHour.toString().padStart(2, '0') + ':00',
      endTime: endHour.toString().padStart(2, '0') + ':00' };
    this.editedSlots = this.editedSlots.concat([next]);
    this.availabilityHint = '';
  }

  private removeSlot(slotId: string): void {
    this.editedSlots = this.editedSlots.filter((slot: V03FairEditableSlot): boolean => slot.slotId !== slotId);
  }

  private chooseSlotTime(slotId: string, chooseStart: boolean): void {
    const current: V03FairEditableSlot | undefined = this.editedSlots.find(
      (slot: V03FairEditableSlot): boolean => slot.slotId === slotId);
    if (current === undefined) { return; }
    const time: string = chooseStart ? current.startTime : current.endTime;
    const selected: Date = new Date();
    selected.setHours(Number(time.substring(0, 2)), Number(time.substring(3, 5)), 0, 0);
    this.getUIContext().showTimePickerDialog({
      selected: selected, useMilitaryTime: true,
      onAccept: (result: TimePickerResult) => {
        const formatted: string = result.hour.toString().padStart(2, '0') + ':' +
          result.minute.toString().padStart(2, '0');
        this.editedSlots = this.editedSlots.map((slot: V03FairEditableSlot): V03FairEditableSlot => {
          if (slot.slotId !== slotId) { return slot; }
          return { slotId: slot.slotId, date: slot.date,
            startTime: chooseStart ? formatted : slot.startTime,
            endTime: chooseStart ? slot.endTime : formatted };
        });
        this.availabilityHint = '';
      }
    });
  }

  private async saveAvailability(): Promise<void> {
    const minutes: number = Number(this.maxMinutes);
    if (!Number.isInteger(minutes) || minutes < 0 || minutes > 600) {
      this.availabilityHint = '每周可投入时间须为 0—600 分钟'; return;
    }
    const slots: V03Slot[] = [];
    for (let index: number = 0; index < this.editedSlots.length; index += 1) {
      const item: V03FairEditableSlot = this.editedSlots[index];
      if (item.startTime >= item.endTime) {
        this.availabilityHint = item.date + ' 的结束时间须晚于开始时间'; return;
      }
      for (let previous: number = 0; previous < index; previous += 1) {
        const other: V03FairEditableSlot = this.editedSlots[previous];
        if (item.date === other.date && item.startTime < other.endTime && item.endTime > other.startTime) {
          this.availabilityHint = item.date + ' 的可用时段不能重叠'; return;
        }
      }
      slots.push({ date: item.date, startTime: item.startTime, endTime: item.endTime });
    }
    try {
      const saved: V03Availability = await HomeFlowV03.saveAvailability(
        this.dateKey(this.monday()), slots, minutes, this.availabilityVersion);
      this.availabilityVersion = saved.version;
      this.availabilityHint = '';
      this.showAvailability = false;
      this.hint = '可用时间已保存';
    } catch (error) { this.availabilityHint = (error as Error).message; }
  }

  private async generate(): Promise<void> {
    if (this.busy) { return; }
    this.busy = true;
    try {
      this.currentSchedule = await HomeFlowV03.generateSchedule(this.dateKey(this.monday()));
      this.hint = this.currentSchedule.status === 'infeasible' ? '当前条件下无法完成排班' : '草案已生成';
    } catch (error) { this.hint = (error as Error).message; }
    finally { this.busy = false; }
  }

  private async publish(): Promise<void> {
    if (this.currentSchedule === null || this.busy) { return; }
    this.busy = true;
    try {
      this.currentSchedule = await HomeFlowV03.publishSchedule(this.dateKey(this.monday()),
        this.currentSchedule.id, this.currentSchedule.version);
      HomeFlowApi.notifyTasksChanged();
      await this.loadWeek();
      this.hint = '排班已发布';
    } catch (error) { this.hint = (error as Error).message; }
    finally { this.busy = false; }
  }

  private canPublish(): boolean {
    if (HomeFlowApi.currentSpace !== null && HomeFlowApi.currentSpace.myRole === 'creator') { return true; }
    if (HomeFlowApi.currentUser === null) { return false; }
    const userId: string = HomeFlowApi.currentUser.id;
    return this.memberList.some((member: HomeFlowMember): boolean =>
      member.userId === userId && member.canPublishSchedule);
  }

  @Builder
  slotEditor(slot: V03FairEditableSlot) {
    Column({ space: 8 }) {
      Row() {
        Text(slot.date.substring(5) + ' 可用时段')
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A').layoutWeight(1)
        Text('删除').fontSize(13).fontColor('#BF715D')
          .onClick(() => this.removeSlot(slot.slotId))
      }.width('100%')
      Row({ space: 8 }) {
        Button('开始 ' + slot.startTime).layoutWeight(1).height(42)
          .fontColor('#34745D').backgroundColor('#E7F3EA')
          .onClick(() => this.chooseSlotTime(slot.slotId, true))
        Text('至').fontSize(13).fontColor('#798780')
        Button('结束 ' + slot.endTime).layoutWeight(1).height(42)
          .fontColor('#34745D').backgroundColor('#E7F3EA')
          .onClick(() => this.chooseSlotTime(slot.slotId, false))
      }.width('100%')
    }.padding(12).width('100%').backgroundColor('#FFFFFF')
      .border({ width: 1, color: '#DCE8DF' }).borderRadius(12).margin({ bottom: 8 })
  }

  @Builder
  availabilitySheet() {
    Column({ space: 12 }) {
      Row() {
        Text('我的可用时间').fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor('#30363A').layoutWeight(1)
        Text('×').fontSize(26).fontColor('#30363A')
          .onClick(() => this.showAvailability = false)
      }.width('100%')
      Text('选择日期，再添加时段并分别设置起止时间。未提交不视为全天有空。')
        .fontSize(13).fontColor('#798780').width('100%')
      Row({ space: 4 }) {
        ForEach(this.weekDates(), (date: string, index: number) => {
          Button(date.substring(8)).layoutWeight(1).height(36).fontSize(12)
            .fontColor(this.selectedDay === index ? '#FFFFFF' : '#34745D')
            .backgroundColor(this.selectedDay === index ? '#4C9C7C' : '#E7F3EA')
            .onClick(() => this.selectedDay = index)
        }, (date: string): string => date)
      }.width('100%')
      Text(this.weekDates()[this.selectedDay] + ' · ' + this.visibleSlots().length.toString() + ' 个时段')
        .fontSize(13).fontColor('#34745D').width('100%')
      Scroll() {
        Column() {
          ForEach(this.visibleSlots(), (slot: V03FairEditableSlot) => {
            this.slotEditor(slot)
          }, (slot: V03FairEditableSlot): string => slot.slotId)
          if (this.visibleSlots().length === 0) {
            Text('这一天尚未添加可用时段').fontSize(13).fontColor('#798780')
              .padding(16).width('100%')
          }
        }.width('100%')
      }.layoutWeight(1).width('100%')
      Button('＋ 添加可用时段').width('100%').height(40)
        .fontColor('#34745D').backgroundColor('#E7F3EA')
        .onClick(() => this.addSlot())
      Text('本周最多投入时间（分钟）').fontSize(14).fontWeight(FontWeight.Bold)
        .fontColor('#30363A').width('100%')
      TextInput({ text: this.maxMinutes, placeholder: '例如 180' })
        .type(InputType.Number).height(46).width('100%')
        .backgroundColor('#FFFFFF').border({ width: 1, color: '#DCE8DF' })
        .onChange((value: string) => this.maxMinutes = value)
      if (this.availabilityHint.length > 0) {
        Text(this.availabilityHint).fontSize(12).fontColor('#BF715D').width('100%')
      }
      Button('保存可用时间').width('100%').height(47).backgroundColor('#4C9C7C')
        .onClick(() => this.saveAvailability())
    }.padding(24).width('100%').height('100%').backgroundColor('#FFF9F2')
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            Row({ space: 10 }) {
              Image($r('app.media.hf_space_back')).width(38).height(38)
                .onClick(() => this.pageStack.pop())
              Column({ space: 2 }) {
                Text('公平排班').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
                Text('看看这周怎样分工更合适').fontSize(13).fontColor('#798780')
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Image($r('app.media.hf_feature_schedule')).width(47).height(47)
            }.width('100%').margin({ top: 12, bottom: 22 })
            Row() {
              Image($r('app.media.hf_space_back')).width(30).height(30)
                .onClick(() => this.changeWeek(-1))
              Text(this.weekLabel()).fontSize(16).fontWeight(FontWeight.Bold)
                .fontColor('#30363A').textAlign(TextAlign.Center).layoutWeight(1)
              Image($r('app.media.hf_space_back')).width(30).height(30)
                .rotate({ angle: 180 }).onClick(() => this.changeWeek(1))
            }.padding(15).width('100%').backgroundColor('#FFFFFF').borderRadius(16)
              .border({ width: 1, color: '#DCE8DF' })
            Row({ space: 11 }) {
              Image($r('app.media.hf_tab_schedule')).width(45).height(45)
              Column({ space: 4 }) {
                Text('可用时间').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#30363A')
                Text(this.memberList.length.toString() + ' 位空间成员')
                  .fontSize(12).fontColor('#798780')
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text('我的设置 ›').fontSize(13).fontWeight(FontWeight.Bold).fontColor('#34745D')
            }.padding(16).width('100%').backgroundColor('#FFFFFF').borderRadius(16)
              .border({ width: 1, color: '#DCE8DF' }).margin({ top: 15 })
              .onClick(() => this.showAvailability = true)
            Column({ space: 12 }) {
              Image($r('app.media.hf_feature_schedule')).width(90).height(90)
              Text(this.currentSchedule === null ? '正在读取本周排班' :
                (this.currentSchedule.status === 'published' ? '本周排班已发布' :
                  (this.currentSchedule.status === 'infeasible' ? '当前条件无法排班' : '本周排班草案')))
                .fontSize(19).fontWeight(FontWeight.Bold).fontColor('#30363A')
              Text('待安排任务 ' + this.unassigned().length.toString() + ' 项。排班草案需要服务端结合可用时间、难度和历史负担计算。')
                .fontSize(13).fontColor('#798780').textAlign(TextAlign.Center)
              Text('生成时会参考：可用时间 · 任务难度 · 近四周分工')
                .fontSize(12).fontColor('#34745D').padding(12)
                .backgroundColor('#E7F3EA').borderRadius(10)
            }.padding(23).width('100%').backgroundColor('#FFFFFF').borderRadius(17)
              .border({ width: 1, color: '#DCE8DF' }).margin({ top: 16 })
            if (this.currentSchedule !== null) {
              ForEach(this.currentSchedule.assignments, (assignment: V03Assignment) => {
                Text(assignment.reason).fontSize(14).fontColor('#30363A')
                  .padding(14).width('100%').backgroundColor('#FFFFFF')
                  .borderRadius(12).margin({ top: 8 })
              }, (assignment: V03Assignment): string => assignment.taskId)
              ForEach(this.currentSchedule.conflicts, (conflict: V03Conflict) => {
                Text(conflict.reason).fontSize(13).fontColor('#BF715D')
                  .padding(12).width('100%')
              }, (conflict: V03Conflict): string => conflict.taskId ?? conflict.reason)
              if (this.currentSchedule.status === 'draft' && this.canPublish()) {
                Button('确认发布排班').width('100%').height(45)
                  .backgroundColor('#4C9C7C').margin({ top: 14 })
                  .onClick(() => this.publish())
              }
            }
            if (this.hint.length > 0) {
              Text(this.hint).fontSize(13).fontColor('#BF715D').margin({ top: 10 })
              Button('重试').backgroundColor('#4C9C7C').onClick(() => this.loadWeek())
            }
            Text('本周待安排任务').fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor('#30363A').width('100%').margin({ top: 23, bottom: 10 })
            ForEach(this.unassigned(), (task: HomeFlowTask) => {
              Text(task.title + ' · ' + task.executionDate)
                .fontSize(14).fontColor('#30363A').padding(15)
                .width('100%').backgroundColor('#FFFFFF').borderRadius(12)
                .margin({ bottom: 8 })
            }, (task: HomeFlowTask): string => task.id)
          }.padding({ left: 24, right: 24, top: 5, bottom: 25 }).width('100%')
        }.layoutWeight(1).width('100%')
          .bindSheet($$this.showAvailability, this.availabilitySheet, {
            height: SheetSize.LARGE, dragBar: false, backgroundColor: '#FFF9F2'
          })
        Button('生成排班草案').width('100%').height(48)
          .fontSize(17).fontWeight(FontWeight.Bold).backgroundColor('#4C9C7C')
          .enabled(!this.busy).onClick(() => this.generate())
          .padding({ left: 24, right: 24, top: 9, bottom: 9 })
      }.width('100%').height('100%')
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
