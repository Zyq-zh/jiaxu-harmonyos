import { HomeFlowApi, HomeFlowMember, HomeFlowTask, HomeFlowTaskDetailData, HomeFlowTaskEditInput, HomeFlowTaskEvent, HomeFlowTaskRouteParam } from '../../api/HomeFlowApi';

@Component
export struct TaskDetailPage {
  pageStack: NavPathStack = new NavPathStack();
  taskId: string = '';
  @State private taskData: HomeFlowTask | null = null;
  @State private canCancel: boolean = false;
  @State private canEdit: boolean = false;
  @State private showEditSheet: boolean = false;
  @State private editTitleText: string = '';
  @State private editCategory: number = 0;
  @State private editDateMillis: number = Date.now();
  @State private editHour: number = 21;
  @State private editMinute: number = 0;
  @State private editMinutesText: string = '25';
  @State private editDifficulty: number = 1;
  @State private editMode: number = 0;
  @State private editHint: string = '';
  @State private savingTitle: boolean = false;
  @State private eventList: HomeFlowTaskEvent[] = [];
  @State private assigneeName: string = '待分配';
  @State private loadHint: string = '';

  aboutToAppear(): void {
    this.loadTask();
  }

  private async loadTask(): Promise<void> {
    if (this.taskId.length === 0) { return; }
    try {
      const detail: HomeFlowTaskDetailData = await HomeFlowApi.taskDetail(this.taskId);
      this.taskData = detail.task;
      this.canCancel = detail.availableActions.includes('cancel');
      this.canEdit = detail.availableActions.includes('edit');
      this.editTitleText = detail.task.title;
      const categoryCodes: string[] = ['floor', 'trash', 'dishes', 'bathroom', 'laundry',
        'supplies', 'plants', 'organizing', 'surfaces', 'other'];
      this.editCategory = Math.max(0, categoryCodes.indexOf(detail.task.category));
      const deadline: Date = new Date(detail.task.deadlineAt);
      this.editDateMillis = deadline.getTime();
      this.editHour = deadline.getHours();
      this.editMinute = deadline.getMinutes();
      this.editMinutesText = detail.task.estimatedMinutes.toString();
      this.editDifficulty = detail.task.difficulty === 'easy' ? 0 :
        (detail.task.difficulty === 'hard' ? 2 : 1);
      this.editMode = detail.task.assignmentMode === 'fair' ? 1 : 0;
      this.editHint = '';
      this.loadHint = '';
      try {
        this.eventList = await HomeFlowApi.taskEvents(this.taskId);
      } catch (error) {
        this.eventList = [];
      }
      if (detail.task.assigneeId !== null) {
        try {
          const members: HomeFlowMember[] = await HomeFlowApi.members();
          const found: HomeFlowMember | undefined = members.find((member: HomeFlowMember): boolean =>
            member.userId === detail.task.assigneeId);
          this.assigneeName = found === undefined ? '已分配' : found.nickname;
        } catch (error) {
          this.assigneeName = '已分配';
        }
      } else {
        this.assigneeName = '待分配';
      }
    } catch (error) {
      this.loadHint = (error as Error).message;
    }
  }

  private editDateKey(): string {
    const date: Date = new Date(this.editDateMillis);
    return date.getFullYear().toString() + '-' +
      (date.getMonth() + 1).toString().padStart(2, '0') + '-' +
      date.getDate().toString().padStart(2, '0');
  }

  private categoryLabel(): string {
    const labels: string[] = ['扫地', '倒垃圾', '洗碗', '卫生间', '洗衣',
      '采购', '植物', '收纳', '擦桌', '其他'];
    return labels[this.editCategory];
  }

  private chooseEditCategory(): void {
    this.getUIContext().showTextPickerDialog({
      range: ['扫地', '倒垃圾', '洗碗', '卫生间', '洗衣', '采购', '植物', '收纳', '擦桌', '其他'],
      selected: this.editCategory,
      onAccept: (value: TextPickerResult) => {
        this.editCategory = Array.isArray(value.index) ? value.index[0] : value.index;
      }
    });
  }

  private chooseEditDate(): void {
    this.getUIContext().showDatePickerDialog({
      selected: new Date(this.editDateMillis), start: new Date(),
      onDateAccept: (date: Date) => this.editDateMillis = date.getTime()
    });
  }

  private chooseEditTime(): void {
    const selected: Date = new Date(this.editDateMillis);
    selected.setHours(this.editHour, this.editMinute, 0, 0);
    this.getUIContext().showTimePickerDialog({
      selected: selected, useMilitaryTime: true,
      onAccept: (value: TimePickerResult) => {
        this.editHour = value.hour;
        this.editMinute = value.minute;
      }
    });
  }

  private chooseEditDifficulty(): void {
    this.getUIContext().showTextPickerDialog({
      range: ['简单', '中等', '较难'], selected: this.editDifficulty,
      onAccept: (value: TextPickerResult) => {
        this.editDifficulty = Array.isArray(value.index) ? value.index[0] : value.index;
      }
    });
  }

  private async saveTask(): Promise<void> {
    if (this.taskData === null || this.savingTitle) { return; }
    const title: string = this.editTitleText.trim();
    if (title.length === 0 || title.length > 60) {
      this.editHint = '任务名称需为 1—60 个字';
      return;
    }
    const minutes: number = Number(this.editMinutesText);
    if (!Number.isInteger(minutes) || minutes < 5 || minutes > 240) {
      this.editHint = '预计用时需为 5—240 分钟';
      return;
    }
    const deadline: Date = new Date(this.editDateMillis);
    deadline.setHours(this.editHour, this.editMinute, 0, 0);
    if (deadline.getTime() <= Date.now()) {
      this.editHint = '截止时间须晚于当前时间';
      return;
    }
    if (this.editMode === 1 && deadline.toDateString() === new Date().toDateString()) {
      this.editHint = '今天的任务请选择我负责';
      return;
    }
    const categories: string[] = ['floor', 'trash', 'dishes', 'bathroom', 'laundry',
      'supplies', 'plants', 'organizing', 'surfaces', 'other'];
    const difficulties: string[] = ['easy', 'medium', 'hard'];
    const input: HomeFlowTaskEditInput = {
      title: title, category: categories[this.editCategory],
      executionDate: this.editDateKey(), deadlineAt: deadline.toISOString(),
      estimatedMinutes: minutes, difficulty: difficulties[this.editDifficulty],
      assignmentMode: this.editMode === 0 ? 'self' : 'fair',
      expectedVersion: this.taskData.version
    };
    this.savingTitle = true;
    try {
      this.taskData = await HomeFlowApi.updateTask(this.taskData.id, input);
      this.showEditSheet = false;
      this.loadHint = '';
      this.editHint = '';
      await this.loadTask();
    } catch (error) {
      this.editHint = (error as Error).message;
    } finally {
      this.savingTitle = false;
    }
  }

  @Builder
  editSheet() {
    Scroll() {
      Column({ space: 13 }) {
        Row() {
          Text('编辑任务').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#30363A').layoutWeight(1)
          Text('取消').fontSize(14).fontColor('#798780').onClick(() => this.showEditSheet = false)
        }.width('100%')
        Text('任务名称').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A').width('100%')
        TextInput({ placeholder: '任务名称', text: this.editTitleText })
          .maxLength(60).height(47).width('100%').backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#DCE8DF' }).borderRadius(12)
          .onChange((value: string) => this.editTitleText = value)
        Text('家务分类').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A').width('100%')
        Button(this.categoryLabel() + '  ›').width('100%').height(45)
          .fontColor('#34745D').backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#DCE8DF' }).onClick(() => this.chooseEditCategory())
        Text('执行日期与截止').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A').width('100%')
        Row({ space: 9 }) {
          Button(this.editDateKey()).layoutWeight(1).height(45)
            .fontColor('#34745D').backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#DCE8DF' }).onClick(() => this.chooseEditDate())
          Button(this.editHour.toString().padStart(2, '0') + ':' +
            this.editMinute.toString().padStart(2, '0')).width(100).height(45)
            .fontColor('#34745D').backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#DCE8DF' }).onClick(() => this.chooseEditTime())
        }.width('100%')
        Text('预计用时（分钟）').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A').width('100%')
        TextInput({ text: this.editMinutesText, placeholder: '5—240' })
          .type(InputType.Number).height(45).width('100%').backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#DCE8DF' })
          .onChange((value: string) => this.editMinutesText = value)
        Text('难度').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A').width('100%')
        Button(this.editDifficulty === 0 ? '简单  ›' :
          (this.editDifficulty === 2 ? '较难  ›' : '中等  ›'))
          .width('100%').height(45).fontColor('#34745D').backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#DCE8DF' }).onClick(() => this.chooseEditDifficulty())
        Text('责任人').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A').width('100%')
        Row({ space: 9 }) {
          Button('我负责').layoutWeight(1).height(43)
            .fontColor(this.editMode === 0 ? '#FFFFFF' : '#34745D')
            .backgroundColor(this.editMode === 0 ? '#4C9C7C' : '#E7F3EA')
            .onClick(() => this.editMode = 0)
          Button('交给公平排班').layoutWeight(1).height(43)
            .fontColor(this.editMode === 1 ? '#FFFFFF' : '#34745D')
            .backgroundColor(this.editMode === 1 ? '#4C9C7C' : '#E7F3EA')
            .onClick(() => this.editMode = 1)
        }.width('100%')
        if (this.editHint.length > 0) {
          Text(this.editHint).fontSize(12).fontColor('#BF715D').width('100%')
        }
        Button(this.savingTitle ? '保存中…' : '保存修改')
          .width('100%').height(48).backgroundColor('#4C9C7C')
          .enabled(!this.savingTitle).onClick(() => this.saveTask())
      }.padding(24).width('100%')
    }.width('100%').height('100%').backgroundColor('#FFF9F2')
  }

  private async cancelTask(): Promise<void> {
    if (this.taskData === null) { return; }
    try {
      await HomeFlowApi.cancelTask(this.taskData.id, this.taskData.version);
      this.pageStack.pop();
    } catch (error) {
      const message: string = (error as Error).message;
      await this.loadTask();
      this.loadHint = message;
    }
  }

  private statusLabel(taskStatus: string): string {
    if (taskStatus === 'unassigned') { return '待分配'; }
    if (taskStatus === 'todo') { return '待完成'; }
    if (taskStatus === 'cancelled') { return '已取消'; }
    if (taskStatus === 'completed') { return '已完成'; }
    if (taskStatus === 'pending_review') { return '待室友审批'; }
    if (taskStatus === 'needs_revision') { return '需要补充'; }
    return '进行中';
  }

  private difficultyLabel(taskDifficulty: string): string {
    if (taskDifficulty === 'easy') { return '简单'; }
    if (taskDifficulty === 'hard') { return '较难'; }
    return '中等';
  }

  private deadlineLabel(deadlineAt: string): string {
    const date: Date = new Date(deadlineAt);
    return (date.getMonth() + 1).toString() + ' 月 ' + date.getDate().toString() + ' 日 ' +
      date.getHours().toString().padStart(2, '0') + ':' +
      date.getMinutes().toString().padStart(2, '0') + ' 前完成';
  }

  private photo(): void {
    const routeParam: HomeFlowTaskRouteParam = { taskId: this.taskId };
    this.pageStack.pushPath({ name: 'TaskEvidence', param: routeParam });
  }

  private swap(): void {
    const routeParam: HomeFlowTaskRouteParam = { taskId: this.taskId };
    this.pageStack.pushPath({ name: 'SwapRequest', param: routeParam });
  }

  @Builder
  infoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14).fontColor('#798780').layoutWeight(1)
      Text(value)
        .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30363A')
    }
    .width('100%').height(47)
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            Row({ space: 13 }) {
              Image($r('app.media.hf_space_back'))
                .width(36).height(36).objectFit(ImageFit.Contain)
                .onClick(() => this.pageStack.pop())
              Column({ space: 2 }) {
                Text('任务详情')
                  .fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
                Text(this.taskData === null ? '加载中' : this.taskData.executionDate)
                  .fontSize(12).fontColor('#798780')
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%').margin({ top: 12, bottom: 20 })

            Column() {
              Row({ space: 13 }) {
                Image($r('app.media.hf_task_sweeping'))
                  .width(69).height(69).objectFit(ImageFit.Contain)
                  .padding(8).backgroundColor('#F0F5EC').borderRadius(15)
                Column({ space: 8 }) {
                  Text(this.taskData === null ? '任务详情' : this.taskData.title)
                    .fontSize(21).fontWeight(FontWeight.Bold).fontColor('#30363A')
                  Text(this.taskData === null ? '' : this.statusLabel(this.taskData.status))
                    .fontSize(13).fontWeight(FontWeight.Bold).fontColor('#34745D')
                    .padding({ left: 13, right: 13, top: 5, bottom: 5 })
                    .backgroundColor('#E7F3EA').borderRadius(10)
                }
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              Text(this.taskData === null ? '' : this.deadlineLabel(this.taskData.deadlineAt))
                .fontSize(14).fontColor('#798780')
                .width('100%').margin({ top: 18 })
            }
            .padding(18).width('100%')
            .backgroundColor('#FFFFFF').borderRadius(16)
            .border({ width: 0.8, color: '#DFEAE2' })
            .shadow({ radius: 8, color: '#18536B56', offsetY: 5 })

            Column() {
              this.infoRow('责任人', this.taskData === null ? '' :
                this.assigneeName)
              Divider().strokeWidth(1).color('#E2EAE3')
              this.infoRow('预计用时', this.taskData === null ? '' :
                this.taskData.estimatedMinutes.toString() + ' 分钟')
              Divider().strokeWidth(1).color('#E2EAE3')
              this.infoRow('任务难度', this.taskData === null ? '' :
                this.difficultyLabel(this.taskData.difficulty))
              Divider().strokeWidth(1).color('#E2EAE3')
              this.infoRow('分配方式', this.taskData === null ? '' :
                (this.taskData.assignmentMode === 'self' ? '我负责' : '待公平排班'))
            }
            .padding({ left: 17, right: 17, top: 6, bottom: 6 })
            .width('100%')
            .backgroundColor('#FFFFFF').borderRadius(16)
            .border({ width: 0.8, color: '#DFEAE2' })
            .shadow({ radius: 8, color: '#18536B56', offsetY: 5 })
            .margin({ top: 15 })

            if (this.loadHint.length > 0) {
              Text(this.loadHint).fontSize(13).fontColor('#BF715D').margin({ top: 12 })
            }
            if (this.canEdit) {
              Button('编辑任务').width('100%').height(44)
                .fontColor('#34745D').backgroundColor('#E7F3EA').borderRadius(12)
                .margin({ top: 14 })
                .onClick(() => this.showEditSheet = true)
            }
            if (this.taskData !== null && this.taskData.status === 'pending_review') {
              Button('查看照片审批').width('100%').height(44)
                .fontColor('#34745D').backgroundColor('#E7F3EA').borderRadius(12)
                .margin({ top: 14 })
                .onClick(() => {
                  const routeParam: HomeFlowTaskRouteParam = { taskId: this.taskId };
                  this.pageStack.pushPath({ name: 'TaskReview', param: routeParam });
                })
            }
            Text('任务记录').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#30363A')
              .width('100%').margin({ top: 21, bottom: 8 })
            ForEach(this.eventList, (entry: HomeFlowTaskEvent) => {
              Text(entry.eventType + ' · ' + entry.createdAt.substring(0, 10))
                .fontSize(12).fontColor('#798780').width('100%').margin({ bottom: 5 })
            }, (entry: HomeFlowTaskEvent): string => entry.id)
            Button('查看分配理由  ›')
              .width('100%').height(49)
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor('#34745D').backgroundColor('#E7F3EA')
              .borderRadius(12).margin({ top: 17 })
              .onClick(() => this.getUIContext().showAlertDialog({
                title: '分配理由',
                message: '公平排班功能将在下一阶段开放。',
                confirm: { value: '知道了', action: () => {} }
              }))
            Text('开工前拍照，完工后拍照，室友审批通过才计入成果。')
              .fontSize(12).fontColor('#798780')
              .width('100%').margin({ top: 21 })
          }
          .padding({ left: 24, right: 24, top: 5, bottom: 22 })
          .width('100%')
        }
        .layoutWeight(1).width('100%')
        .bindSheet($$this.showEditSheet, this.editSheet, {
          height: SheetSize.LARGE, dragBar: false, backgroundColor: '#FFF9F2'
        })
        Row({ space: 12 }) {
          Button('申请换班')
            .layoutWeight(1).height(46)
            .fontSize(14).fontWeight(FontWeight.Bold)
            .fontColor('#34745D').backgroundColor('#E7F3EA')
            .borderRadius(12)
            .enabled(this.taskData !== null && this.taskData.status === 'todo' &&
              HomeFlowApi.currentUser !== null && this.taskData.assigneeId === HomeFlowApi.currentUser.id &&
              new Date(this.taskData.deadlineAt).getTime() > Date.now())
            .onClick(() => this.swap())
          Button('任务照片')
            .layoutWeight(1).height(46)
            .fontSize(14).fontWeight(FontWeight.Bold)
            .backgroundColor('#4C9C7C').borderRadius(12)
            .enabled(this.taskData !== null)
            .onClick(() => this.photo())
        }
        .padding({ left: 24, right: 24, top: 9, bottom: 5 })
        .width('100%').backgroundColor('#FFFFFF')
        if (this.canCancel) {
          Button('取消任务').width('100%').height(43)
            .fontSize(14).fontColor('#BF715D').backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#F0D9D0' }).borderRadius(12)
            .margin({ left: 24, right: 24, bottom: 8 })
            .onClick(() => this.getUIContext().showAlertDialog({
              title: '取消这项任务？',
              message: '取消后任务将保留在历史记录中。',
              primaryButton: { value: '返回', action: () => {} },
              secondaryButton: { value: '取消任务', action: () => this.cancelTask() }
            }))
        }
      }
      .width('100%').height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor('#FFF9F2')
  }
}
