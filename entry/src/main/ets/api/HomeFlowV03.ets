import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { HomeFlowApi, HomeFlowTask } from './HomeFlowApi';
import { HomeFlowPatch } from './HomeFlowPatch';

interface V03Meta { nextCursor?: string | null; }
interface V03Envelope<T> { data: T; meta: V03Meta; }
interface V03Failure { error: V03Error; }
interface V03Error { message: string; }

export interface V03Rule { id: string; content: string; version: number; status: string; }
export interface V03Proposal {
  id: string; type: string; content: string; ruleId: string | null; status: string;
  version: number; canVote: boolean; myVote: string | null; eligibleCount: number; agreeCount: number;
}
export interface V03MemberScore { userId: string; nickname: string; score: number; completedCount: number; }
export interface V03Statistics {
  plannedCount: number; completedCount: number; completionRate: number | null;
  formulaVersion: number; members: V03MemberScore[];
}
export interface V03Suggestion { id: string; text: string; tone: string; }
export interface V03Suggestions { suggestions: V03Suggestion[]; generationId: string; providerStatus: string; }
export interface V03Draft {
  id: string; title: string; body: string; inputText: string; tone: string;
  version: number; createdAt: string; updatedAt: string;
}
export interface V03Notification {
  id: string; type: string; resourceType: string; resourceId: string;
  readAt: string | null; createdAt: string;
}
export interface V03NotificationPreferences {
  version: number; tasks: boolean; reviews: boolean; swaps: boolean;
  rules: boolean; weeklySummary: boolean;
}
export interface V03Slot { date: string; startTime: string; endTime: string; }
export interface V03Availability { version: number; slots: V03Slot[]; maxWeekMinutes: number; submitted: boolean; }
export interface V03Assignment { taskId: string; assigneeId: string; relativeBurden: number; reason: string; }
export interface V03Conflict { taskId?: string; reason: string; }
export interface V03Schedule {
  id: string; version: number; status: string; assignments: V03Assignment[];
  conflicts: V03Conflict[]; currentTasks: HomeFlowTask[];
}
export interface V03Dashboard {
  todayTasks: HomeFlowTask[]; activeRules: V03Rule[]; unreadNotificationCount: number;
  completionSummary: V03Statistics;
}
export interface V03Negotiation { id: string; status: string; version: number; type: string; }

export class HomeFlowV03 {
  private static readonly base: string = 'http://193.112.29.130/api/v1';

  static newKey(): string { return util.generateRandomUUID(); }

  private static spacePath(): string {
    if (HomeFlowApi.currentSpace === null) { throw new Error('请先加入空间'); }
    return '/spaces/' + HomeFlowApi.currentSpace.id;
  }

  private static async envelope<T>(method: http.RequestMethod, path: string,
    body: string = '', key: string = ''): Promise<V03Envelope<T>> {
    if (HomeFlowApi.refreshToken.length > 0 && Date.now() >= HomeFlowApi.accessExpiresAt) {
      await HomeFlowApi.refresh();
    }
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    headers['Authorization'] = 'Bearer ' + HomeFlowApi.accessToken;
    if (key.length > 0) { headers['Idempotency-Key'] = key; }
    const client: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await client.request(HomeFlowV03.base + path, {
        method: method, header: headers, extraData: body,
        expectDataType: http.HttpDataType.STRING, usingCache: false, usingProxy: false,
        connectTimeout: 10000, readTimeout: 30000
      });
      if (response.responseCode === 204) {
        return { data: JSON.parse('null') as T, meta: {} };
      }
      const raw: string = response.result.toString();
      if (response.responseCode >= 200 && response.responseCode < 300) {
        return JSON.parse(raw) as V03Envelope<T>;
      }
      const failure: V03Failure = JSON.parse(raw) as V03Failure;
      throw new Error(failure.error.message);
    } catch (error) {
      const issue: Error = error as Error;
      throw new Error(issue.message.length > 0 ? issue.message : '网络请求失败');
    } finally { client.destroy(); }
  }

  private static async data<T>(method: http.RequestMethod, path: string,
    body: string = '', key: string = ''): Promise<T> {
    return (await HomeFlowV03.envelope<T>(method, path, body, key)).data;
  }

  static rules(): Promise<V03Rule[]> {
    return HomeFlowV03.data<V03Rule[]>(http.RequestMethod.GET, HomeFlowV03.spacePath() + '/rules');
  }
  static proposals(status: string = ''): Promise<V03Proposal[]> {
    const query: string = status.length > 0 ? '?status=' + encodeURIComponent(status) : '';
    return HomeFlowV03.data<V03Proposal[]>(http.RequestMethod.GET,
      HomeFlowV03.spacePath() + '/rule-proposals' + query);
  }
  static propose(content: string, ruleId: string = '', key: string = HomeFlowV03.newKey()): Promise<V03Proposal> {
    const payload: V03ProposalInput = ruleId.length > 0 ?
      { type: 'delete', ruleId: ruleId } : { type: 'add', content: content };
    return HomeFlowV03.data<V03Proposal>(http.RequestMethod.POST,
      HomeFlowV03.spacePath() + '/rule-proposals', JSON.stringify(payload), key);
  }
  static voteProposal(id: string, version: number, choice: string, key: string = HomeFlowV03.newKey()): Promise<V03Proposal> {
    const payload: V03VoteInput = { expectedVersion: version, choice: choice };
    return HomeFlowV03.data<V03Proposal>(http.RequestMethod.POST,
      '/rule-proposals/' + id + '/votes', JSON.stringify(payload), key);
  }
  static statistics(from: string, to: string): Promise<V03Statistics> {
    return HomeFlowV03.data<V03Statistics>(http.RequestMethod.GET,
      HomeFlowV03.spacePath() + '/statistics?from=' + from + '&to=' + to);
  }
  static dashboard(date: string): Promise<V03Dashboard> {
    return HomeFlowV03.data<V03Dashboard>(http.RequestMethod.GET,
      HomeFlowV03.spacePath() + '/dashboard?date=' + date);
  }
  static suggestions(concernText: string, tone: string): Promise<V03Suggestions> {
    const payload: V03SuggestInput = { concernText: concernText, tone: tone, requestId: HomeFlowV03.newKey() };
    return HomeFlowV03.data<V03Suggestions>(http.RequestMethod.POST,
      '/communication/suggestions', JSON.stringify(payload));
  }
  static drafts(): Promise<V03Draft[]> {
    return HomeFlowV03.data<V03Draft[]>(http.RequestMethod.GET, '/me/communication-drafts');
  }
  static createDraft(title: string, body: string, inputText: string, tone: string,
    key: string = HomeFlowV03.newKey()): Promise<V03Draft> {
    const payload: V03DraftInput = { title: title, body: body, inputText: inputText, tone: tone };
    return HomeFlowV03.data<V03Draft>(http.RequestMethod.POST, '/me/communication-drafts',
      JSON.stringify(payload), key);
  }
  static async updateDraft(id: string, version: number, title: string, body: string, tone: string): Promise<V03Draft> {
    const payload: V03DraftPatchInput = { expectedVersion: version, title: title, body: body, tone: tone };
    await HomeFlowApi.ensureAccessToken();
    return HomeFlowPatch.request<V03Draft>(HomeFlowV03.base +
      '/me/communication-drafts/' + id, JSON.stringify(payload), HomeFlowApi.accessToken);
  }
  static deleteDraft(id: string, version: number): Promise<void> {
    return HomeFlowV03.data<void>(http.RequestMethod.DELETE,
      '/me/communication-drafts/' + id + '?expectedVersion=' + version.toString());
  }
  static notifications(): Promise<V03Notification[]> {
    return HomeFlowV03.data<V03Notification[]>(http.RequestMethod.GET, '/me/notifications');
  }
  static readNotification(id: string, key: string = HomeFlowV03.newKey()): Promise<void> {
    return HomeFlowV03.data<void>(http.RequestMethod.POST, '/me/notifications/' + id + '/read', '', key);
  }
  static notificationPreferences(): Promise<V03NotificationPreferences> {
    return HomeFlowV03.data<V03NotificationPreferences>(http.RequestMethod.GET, '/me/notification-preferences');
  }
  static async saveNotificationPreferences(input: V03NotificationPreferences): Promise<V03NotificationPreferences> {
    await HomeFlowApi.ensureAccessToken();
    return HomeFlowPatch.request<V03NotificationPreferences>(HomeFlowV03.base +
      '/me/notification-preferences', JSON.stringify({ expectedVersion: input.version,
        tasks: input.tasks, reviews: input.reviews, swaps: input.swaps,
        rules: input.rules, weeklySummary: input.weeklySummary }), HomeFlowApi.accessToken);
  }
  static availability(week: string): Promise<V03Availability> {
    return HomeFlowV03.data<V03Availability>(http.RequestMethod.GET,
      HomeFlowV03.spacePath() + '/weeks/' + week + '/availability/me');
  }
  static saveAvailability(week: string, slots: V03Slot[], minutes: number,
    version: number): Promise<V03Availability> {
    const payload: V03AvailabilityInput = { slots: slots, maxWeekMinutes: minutes, expectedVersion: version };
    return HomeFlowV03.data<V03Availability>(http.RequestMethod.PUT,
      HomeFlowV03.spacePath() + '/weeks/' + week + '/availability/me', JSON.stringify(payload));
  }
  static schedule(week: string): Promise<V03Schedule> {
    return HomeFlowV03.data<V03Schedule>(http.RequestMethod.GET,
      HomeFlowV03.spacePath() + '/weeks/' + week + '/schedule');
  }
  static generateSchedule(week: string, key: string = HomeFlowV03.newKey()): Promise<V03Schedule> {
    return HomeFlowV03.data<V03Schedule>(http.RequestMethod.POST,
      HomeFlowV03.spacePath() + '/weeks/' + week + '/schedule/drafts', '', key);
  }
  static publishSchedule(week: string, draftId: string, version: number,
    key: string = HomeFlowV03.newKey()): Promise<V03Schedule> {
    const payload: V03PublishInput = { draftId: draftId, expectedVersion: version };
    return HomeFlowV03.data<V03Schedule>(http.RequestMethod.POST,
      HomeFlowV03.spacePath() + '/weeks/' + week + '/schedule/publish', JSON.stringify(payload), key);
  }
  static swapCandidates(taskId: string): Promise<HomeFlowTask[]> {
    return HomeFlowV03.data<HomeFlowTask[]>(http.RequestMethod.GET,
      '/tasks/' + taskId + '/swap-candidates');
  }
  static swap(sourceTaskId: string, targetTaskId: string, sourceVersion: number,
    targetVersion: number, reason: string, key: string = HomeFlowV03.newKey()): Promise<V03Negotiation> {
    const payload: V03SwapInput = { sourceTaskId: sourceTaskId, targetTaskId: targetTaskId,
      sourceVersion: sourceVersion, targetVersion: targetVersion, reason: reason };
    return HomeFlowV03.data<V03Negotiation>(http.RequestMethod.POST, '/swap-requests', JSON.stringify(payload), key);
  }
}

interface V03ProposalInput { type: string; content?: string; ruleId?: string; }
interface V03VoteInput { expectedVersion: number; choice: string; }
interface V03SuggestInput { concernText: string; tone: string; requestId: string; }
interface V03DraftInput { title: string; body: string; inputText: string; tone: string; }
interface V03DraftPatchInput { expectedVersion: number; title: string; body: string; tone: string; }
interface V03AvailabilityInput { slots: V03Slot[]; maxWeekMinutes: number; expectedVersion: number; }
interface V03PublishInput { draftId: string; expectedVersion: number; }
interface V03SwapInput { sourceTaskId: string; targetTaskId: string; sourceVersion: number; targetVersion: number; reason: string; }
