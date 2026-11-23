import { HomeFlowApi } from '../../api/HomeFlowApi';
import { HomeFlowV03, V03Proposal, V03Rule } from '../../api/HomeFlowV03';

@Component
export struct RulesPage {
  pageStack: NavPathStack = new NavPathStack();
  @State private section: number = 0;
  @State private showAddSheet: boolean = false;
  @State private showDeleteSheet: boolean = false;
  @State private ruleText: string = '';
  @State private hint: string = '';
  @State private ruleList: V03Rule[] = [];
  @State private proposalList: V03Proposal[] = [];
  @State private selectedRuleId: string = '';
  @State private busy: boolean = false;

  aboutToAppear(): void { this.load(); }

  private async load(): Promise<void> {
    try {
      this.ruleList = await HomeFlowV03.rules();
      this.proposalList = await HomeFlowV03.proposals();
      this.hint = '';
    } catch (error) { this.hint = (error as Error).message; }
  }

  private spaceLabel(): string {
    if (HomeFlowApi.currentSpace === null) { return '当前空间'; }
    return HomeFlowApi.currentSpace.name;
  }

  private async submit(): Promise<void> {
    if (this.ruleText.trim().length === 0) {
      this.hint = '请输入规则内容';
      return;
    }
    if (this.busy) { return; }
    this.busy = true;
    try {
      await HomeFlowV03.propose(this.ruleText.trim());
      HomeFlowApi.notifyTasksChanged();
      this.showAddSheet = false;
      this.ruleText = '';
      await this.load();
    } catch (error) { this.hint = (error as Error).message; }
    finally { this.busy = false; }
  }

  private async deleteRule(): Promise<void> {
    if (this.selectedRuleId.length === 0 || this.busy) { return; }
    this.busy = true;
    try {
      await HomeFlowV03.propose('', this.selectedRuleId);
      HomeFlowApi.notifyTasksChanged();
      this.showDeleteSheet = false;
      this.selectedRuleId = '';
      await this.load();
    } catch (error) { this.hint = (error as Error).message; }
    finally { this.busy = false; }
  }

  private async vote(proposal: V03Proposal, choice: string): Promise<void> {
    if (this.busy) { return; }
    this.busy = true;
    try {
      await HomeFlowV03.voteProposal(proposal.id, proposal.version, choice);
      HomeFlowApi.notifyTasksChanged();
      await this.load();
    } catch (error) { this.hint = (error as Error).message; }
    finally { this.busy = false; }
  }

  private visibleProposals(): V03Proposal[] {
    if (this.section === 0) {
      return this.proposalList.filter((item: V03Proposal): boolean => item.canVote);
    }
    return this.proposalList.filter((item: V03Proposal): boolean => item.status !== 'pending');
  }

  @Builder
  addSheet() {
    Column({ space: 13 }) {
      Row() {
        Text('新增' + (HomeFlowApi.currentSpace !== null && HomeFlowApi.currentSpace.scene === 'shared' ?
          '合租' : '宿舍') + '规则')
          .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#30363A').layoutWeight(1)
        Text('×').fontSize(26).fontColor('#30363A').onClick(() => this.showAddSheet = false)
      }.width('100%')
      Text('提交后由空间成员表决，全员同意才会生效。')
        .fontSize(13).fontColor('#798780').width('100%')
      TextArea({ placeholder: '输入最多 120 字的规则', text: this.ruleText })
        .maxLength(120).height(90).width('100%')
        .fontSize(15).fontColor('#30363A').backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#DCE8DF' }).borderRadius(12)
        .onChange((value: string) => { this.ruleText = value; this.hint = ''; })
      Text(this.ruleText.length.toString() + ' / 120')
        .fontSize(12).fontColor('#798780').width('100%').textAlign(TextAlign.End)
      if (this.hint.length > 0) {
        Text(this.hint).fontSize(12).fontColor('#BF715D').width('100%')
      }
      Button('提交投票').width('100%').height(48)
        .fontSize(16).fontWeight(FontWeight.Bold).backgroundColor('#4C9C7C')
        .onClick(() => this.submit())
    }.width('100%').padding(24).backgroundColor('#FFF9F2')
  }

  @Builder
  deleteSheet() {
    Column({ space: 16 }) {
      Row() {
        Text('提议删除规则').fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor('#30363A').layoutWeight(1)
        Text('×').fontSize(26).fontColor('#30363A').onClick(() => this.showDeleteSheet = false)
      }.width('100%')
      Text('选择一条已生效规则，提交删除提案后由成员表决。')
        .fontSize(14).fontColor('#798780').width('100%')
      ForEach(this.ruleList, (rule: V03Rule) => {
        Row() {
          Text(rule.content).layoutWeight(1).fontSize(14).fontColor('#30363A')
          Text(this.selectedRuleId === rule.id ? '✓' : '○').fontColor('#34745D')
        }.padding(13).width('100%').backgroundColor('#FFFFFF').borderRadius(12)
          .onClick(() => this.selectedRuleId = rule.id)
      }, (rule: V03Rule): string => rule.id)
      Button('提交删除提案').width('100%').height(46).backgroundColor('#4C9C7C')
        .enabled(this.selectedRuleId.length > 0 && !this.busy).onClick(() => this.deleteRule())
    }.padding(24).width('100%').backgroundColor('#FFF9F2')
  }

  @Builder
  sectionButton(label: string, index: number) {
    Button(label).layoutWeight(1).height(38).fontSize(13)
      .fontWeight(this.section === index ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.section === index ? '#FFFFFF' : '#34745D')
      .backgroundColor(this.section === index ? '#4C9C7C' : '#E7F3EA')
      .borderRadius(10).onClick(() => this.section = index)
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            Row({ space: 13 }) {
              Image($r('app.media.hf_space_back')).width(38).height(38)
                .onClick(() => this.pageStack.pop())
              Column({ space: 3 }) {
                Text(HomeFlowApi.currentSpace !== null && HomeFlowApi.currentSpace.scene === 'shared' ?
                  '合租规则' : '宿舍规则')
                  .fontSize(25).fontWeight(FontWeight.Bold).fontColor('#30363A')
                Text(this.spaceLabel()).fontSize(13).fontColor('#798780')
              }.alignItems(HorizontalAlign.Start)
            }.width('100%').margin({ top: 12, bottom: 20 })
            Row({ space: 14 }) {
              Image($r('app.media.hf_feature_consensus')).width(54).height(54)
              Column({ space: 7 }) {
                Text('共同遵守的小约定').fontSize(19).fontWeight(FontWeight.Bold).fontColor('#34745D')
                Text('全员同意后生效').fontSize(13).fontColor('#798780')
              }.alignItems(HorizontalAlign.Start)
            }.padding(18).width('100%').backgroundColor('#E7F3EA').borderRadius(16)
            Text('空间规则').fontSize(19).fontWeight(FontWeight.Bold).fontColor('#30363A')
              .width('100%').margin({ top: 25, bottom: 12 })
            Row({ space: 7 }) {
              this.sectionButton('待我回应', 0)
              this.sectionButton('已生效', 1)
              this.sectionButton('表决记录', 2)
            }.width('100%')
            if (this.section === 1) {
              ForEach(this.ruleList, (rule: V03Rule) => {
                Text(rule.content).fontSize(15).fontColor('#30363A')
                  .padding(18).width('100%').backgroundColor('#FFFFFF')
                  .borderRadius(13).margin({ top: 10 })
              }, (rule: V03Rule): string => rule.id)
            } else {
              ForEach(this.visibleProposals(), (proposal: V03Proposal) => {
                Column({ space: 9 }) {
                  Text((proposal.type === 'delete' ? '删除规则' : '新增规则') + ' · ' + proposal.status)
                    .fontSize(14).fontColor('#34745D').width('100%')
                  Text(proposal.content).fontSize(16).fontColor('#30363A').width('100%')
                  Text('同意 ' + proposal.agreeCount.toString() + ' / ' + proposal.eligibleCount.toString())
                    .fontSize(12).fontColor('#798780').width('100%')
                  if (proposal.canVote) {
                    Row({ space: 10 }) {
                      Button('不同意').layoutWeight(1).backgroundColor('#E7F3EA')
                        .fontColor('#34745D').onClick(() => this.vote(proposal, 'disagree'))
                      Button('同意').layoutWeight(1).backgroundColor('#4C9C7C')
                        .onClick(() => this.vote(proposal, 'agree'))
                    }.width('100%')
                  }
                }.padding(16).width('100%').backgroundColor('#FFFFFF')
                  .borderRadius(13).margin({ top: 10 })
              }, (proposal: V03Proposal): string => proposal.id)
            }
            if ((this.section === 1 && this.ruleList.length === 0) ||
              (this.section !== 1 && this.visibleProposals().length === 0)) {
              Text('暂无记录').padding(20).fontColor('#798780')
            }
            if (this.hint.length > 0) {
              Text(this.hint).fontSize(13).fontColor('#BF715D').margin({ top: 10 })
            }
          }.padding({ left: 24, right: 24, top: 5, bottom: 24 }).width('100%')
        }.layoutWeight(1).width('100%')
          .bindSheet($$this.showAddSheet, this.addSheet, {
            height: SheetSize.MEDIUM, dragBar: false, backgroundColor: '#FFF9F2'
          })
        Column({ space: 9 }) {
          Button('新增规则').width('100%').height(46)
            .backgroundColor('#4C9C7C').borderRadius(12)
            .onClick(() => this.showAddSheet = true)
          Button('提议删除').width('100%').height(45)
            .fontColor('#34745D').backgroundColor('#E7F3EA').borderRadius(12)
            .onClick(() => this.showDeleteSheet = true)
        }.padding({ left: 24, right: 24, top: 10, bottom: 10 })
          .width('100%').backgroundColor('#FFFFFF')
      }.width('100%').height('100%')
        .bindSheet($$this.showDeleteSheet, this.deleteSheet, {
          height: SheetSize.MEDIUM, dragBar: false, backgroundColor: '#FFF9F2'
        })
    }.hideTitleBar(true).backgroundColor('#FFF9F2')
  }
}
