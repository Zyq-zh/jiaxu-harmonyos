import { HomeFlowApi, HomeFlowTask, HomeFlowTaskRouteParam } from '../../api/HomeFlowApi';

@Component
export struct AllTasksPage {
  pageStack: NavPathStack = new NavPathStack();
  @State private startMillis: number = Date.now();
  @State private endMillis: number = Date.now() + 30 * 24 * 60 * 60 * 1000;
  @State private selectedStatus: number = 0;
  @State private allTasks: HomeFlowTask[] = [];
  @State private loadHint: string = '';
  @State private loading: boolean = false;
  @StorageLink('homeflowTaskRevision') @Watch('onTaskChanged') private sharedTaskRevision: number = 0;

  aboutToAppear(): void {
    this.loadTasks();
  }

  private onTaskChanged(): void { this.loadTasks(); }

  private dateKey(millis: number): string {
    const date: Date = new Date(millis);
    return date.getFullYear().toString() + '-' +
      (date.getMonth() + 1).toString().padStart(2, '0') + '-' +
      date.getDate().toString().padStart(2, '0');
  }

  private async loadTasks(): Promise<void> {
    if (this.loading) { return; }
    this.loading = true;
    try {
      this.allTasks = await HomeFlowApi.tasks(this.dateKey(this.startMillis), this.dateKey(this.endMillis));
      this.loadHint = '';
    } catch (error) {
      this.loadHint = (error as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private filteredTasks(): HomeFlowTask[] {
    if (this.selectedStatus === 0) { return this.allTasks; }
    return this.allTasks.filter((task: HomeFlowTask): boolean => {
      if (this.selectedStatus === 1) { return task.status === 'todo' || task.status === 'unassigned'; }
      if (this.selectedStatus === 2) { return task.status === 'completed'; }
      return task.status === 'cancelled';
    });
  }

  private chooseStart(): void {
    this.getUIContext().showDatePickerDialog({
      selected: new Date(this.startMillis),
      onDateAccept: (date: Date) => {
        this.startMillis = date.getTime();
        if (this.dateKey(this.endMillis) < this.dateKey(this.startMillis) ||
          this.rangeDays(new Date(this.endMillis), date) > 61) {
          this.endMillis = this.startMillis;
        }
        this.loadTasks();
      }
    });
  }

  private chooseEnd(): void {
    this.getUIContext().showDatePickerDialog({
      selected: new Date(this.endMillis),
      onDateAccept: (date: Date) => {
        const days: number = this.rangeDays(date, new Date(this.startMillis));
        if (days < 0 || days > 61) {
          this.loadHint = '查询范围最多 62 天';
          return;
        }
        this.endMillis = date.getTime();
        this.loadTasks();
      }
    });
  }

  private rangeDays(end: Date, start: Date): number {
    return (Date.UTC(end.getFullYear(), end.getMonth(), end.getDate()) -
      Date.UTC(start.getFullYear(), start.getMonth(), start.getDate())) / 86400000;
  }

  @Builder
  filterButton(label: string, code: number) {
    Button(label).layoutWeight(1).height(36).fontSize(12)
      .fontColor(this.selectedStatus === code ? '#FFFFFF' : '#34745D')
      .backgroundColor(this.selectedStatus === code ? '#4C9C7C' : '#E7F3EA')
      .onClick(() => this.selectedStatus = code)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Row({ space: 13 }) {
            Image($r('app.media.hf_space_back')).width(38).height(38)
              .onClick(() => this.pageStack.pop())
            Text('全部任务').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
          }.width('100%').margin({ top: 12, bottom: 20 })
          Row({ space: 8 }) {
            Button(this.dateKey(this.startMillis)).layoutWeight(1).height(42)
              .fontColor('#34745D').backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#DCE8DF' }).onClick(() => this.chooseStart())
            Text('至').fontSize(13).fontColor('#798780')
            Button(this.dateKey(this.endMillis)).layoutWeight(1).height(42)
              .fontColor('#34745D').backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#DCE8DF' }).onClick(() => this.chooseEnd())
          }.width('100%')
          Row({ space: 7 }) {
            this.filterButton('全部', 0)
            this.filterButton('待完成', 1)
            this.filterButton('已完成', 2)
            this.filterButton('已取消', 3)
          }.width('100%').margin({ top: 16, bottom: 18 })
          if (this.loading) {
            Text('正在加载任务…').fontSize(13).fontColor('#798780')
          }
          if (this.loadHint.length > 0) {
            Text(this.loadHint).fontSize(13).fontColor('#BF715D')
            Button('重试').backgroundColor('#4C9C7C').onClick(() => this.loadTasks())
          }
          ForEach(this.filteredTasks(), (task: HomeFlowTask) => {
            Row({ space: 12 }) {
              Image(task.category === 'trash' ? $r('app.media.hf_task_trash') :
                $r('app.media.hf_task_sweeping'))
                .width(44).height(44).objectFit(ImageFit.Contain)
              Column({ space: 5 }) {
                Text(task.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#30363A')
                Text(task.executionDate + ' · ' + task.status).fontSize(12).fontColor('#798780')
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text('›').fontSize(23).fontColor('#798780')
            }.padding(14).width('100%').backgroundColor('#FFFFFF').borderRadius(14)
              .border({ width: 1, color: '#DCE8DF' }).margin({ bottom: 9 })
              .onClick(() => {
                const routeParam: HomeFlowTaskRouteParam = { taskId: task.id };
                this.pageStack.pushPath({ name: 'TaskDetail', param: routeParam });
              })
          }, (task: HomeFlowTask): string => task.id)
          if (!this.loading && this.filteredTasks().length === 0) {
            Text('此范围暂无任务').fontSize(14).fontColor('#798780')
              .width('100%').textAlign(TextAlign.Center).padding(35)
          }
        }.width('100%').padding({ left: 24, right: 24, top: 5, bottom: 24 })
      }.width('100%').height('100%')
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
