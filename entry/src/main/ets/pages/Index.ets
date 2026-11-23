import { LoginPage } from './auth/LoginPage';
import { RegisterPage } from './auth/RegisterPage';
import { CreateSpacePage } from './space/CreateSpacePage';
import { MainShellPage } from './main/MainShellPage';
import { TaskDetailPage } from './task/TaskDetailPage';
import { AllTasksPage } from './task/AllTasksPage';
import { SuggestionsPage } from './main/SuggestionsPage';
import { HomeFlowSuggestionRouteParam, HomeFlowTaskRouteParam } from '../api/HomeFlowApi';
import { ProfilePage } from './settings/ProfilePage';
import { MembersPage } from './space/MembersPage';
import { RulesPage } from './rules/RulesPage';
import { StatisticsPage } from './stats/StatisticsPage';
import { FairSchedulePage } from './schedule/FairSchedulePage';
import { DraftsPage } from './settings/DraftsPage';
import { NotificationSettingsPage } from './settings/NotificationSettingsPage';
import { PrivacyPage } from './settings/PrivacyPage';
import { NotificationsPage } from './settings/NotificationsPage';
import { SwapRequestPage } from './schedule/SwapRequestPage';
import { TaskEvidencePage } from './task/TaskEvidencePage';
import { TaskReviewPage } from './task/TaskReviewPage';

@Entry
@Component
struct Index {
  private pageStack: NavPathStack = new NavPathStack();

  @Builder
  destination(name: string, param: Object) {
    if (name === 'CreateSpace') {
      CreateSpacePage({ pageStack: this.pageStack })
    } else if (name === 'Main') {
      MainShellPage({ pageStack: this.pageStack })
    } else if (name === 'Register') {
      RegisterPage({ pageStack: this.pageStack })
    } else if (name === 'Privacy') {
      PrivacyPage({ pageStack: this.pageStack })
    } else if (name === 'TaskDetail') {
      TaskDetailPage({ pageStack: this.pageStack,
        taskId: (param as HomeFlowTaskRouteParam).taskId })
    } else if (name === 'Notifications') {
      NotificationsPage({ pageStack: this.pageStack })
    } else if (name === 'AllTasks') {
      AllTasksPage({ pageStack: this.pageStack })
    } else if (name === 'RuleProposals') {
      RulesPage({ pageStack: this.pageStack })
    } else if (name === 'Statistics') {
      StatisticsPage({ pageStack: this.pageStack })
    } else if (name === 'FairSchedule') {
      FairSchedulePage({ pageStack: this.pageStack })
    } else if (name === 'Suggestions') {
      SuggestionsPage({ pageStack: this.pageStack, concernText: (param as HomeFlowSuggestionRouteParam).concernText,
        initialTone: (param as HomeFlowSuggestionRouteParam).tone })
    } else if (name === 'Profile') {
      ProfilePage({ pageStack: this.pageStack })
    } else if (name === 'Drafts') {
      DraftsPage({ pageStack: this.pageStack })
    } else if (name === 'Members') {
      MembersPage({ pageStack: this.pageStack })
    } else if (name === 'NotificationSettings') {
      NotificationSettingsPage({ pageStack: this.pageStack })
    } else if (name === 'SwapRequest') {
      SwapRequestPage({ pageStack: this.pageStack, taskId: (param as HomeFlowTaskRouteParam).taskId })
    } else if (name === 'TaskEvidence') {
      TaskEvidencePage({ pageStack: this.pageStack, taskId: (param as HomeFlowTaskRouteParam).taskId })
    } else if (name === 'TaskReview') {
      TaskReviewPage({ pageStack: this.pageStack, taskId: (param as HomeFlowTaskRouteParam).taskId })
    }
  }

  build() {
    Navigation(this.pageStack) {
      LoginPage({ pageStack: this.pageStack })
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.destination)
    .width('100%')
    .height('100%')
  }
}
