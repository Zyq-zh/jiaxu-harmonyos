import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { HomeFlowPatch } from './HomeFlowPatch';

export interface HomeFlowSpace {
  id: string;
  name: string;
  scene: string;
  myRole: string;
  memberCount: number;
}

export interface HomeFlowUser {
  id: string;
  account: string;
  nickname: string;
  version: number;
}

export interface HomeFlowMember {
  id: string;
  userId: string;
  nickname: string;
  role: string;
  canPublishSchedule: boolean;
  version: number;
}

export interface HomeFlowInvitation {
  invitationCode: string;
  expiresAt: string;
}

export interface HomeFlowMe {
  user: HomeFlowUser;
  currentSpace: HomeFlowSpace | null;
}

export interface HomeFlowTaskEvent {
  id: string;
  eventType: string;
  createdAt: string;
}

export interface HomeFlowTask {
  id: string;
  title: string;
  category: string;
  executionDate: string;
  deadlineAt: string;
  estimatedMinutes: number;
  difficulty: string;
  assignmentMode: string;
  assigneeId: string | null;
  status: string;
  version: number;
}

export interface HomeFlowTaskInput {
  title: string;
  category: string;
  executionDate: string;
  deadlineAt: string;
  estimatedMinutes: number;
  difficulty: string;
  assignmentMode: string;
}

export interface HomeFlowTaskRouteParam {
  taskId: string;
}

export interface HomeFlowSuggestionRouteParam {
  concernText: string;
  tone: number;
}

interface HomeFlowEnvelope<T> {
  data: T;
  meta?: HomeFlowResponseMeta;
}

interface HomeFlowResponseMeta {
  nextCursor?: string | null;
}

interface HomeFlowErrorBody {
  message: string;
}

interface HomeFlowErrorEnvelope {
  error: HomeFlowErrorBody;
}

interface HomeFlowLoginData {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  user: HomeFlowUser;
  currentSpace: HomeFlowSpace | null;
}

interface HomeFlowLoginInput {
  account: string;
  password: string;
}

interface HomeFlowRegisterInput {
  account: string;
  password: string;
  nickname: string;
}

interface HomeFlowRefreshInput {
  refreshToken: string;
}

interface HomeFlowSpaceInput {
  name: string;
  scene: string;
}

interface HomeFlowJoinInput {
  invitationCode: string;
}

interface HomeFlowCancelInput {
  expectedVersion: number;
}

interface HomeFlowProfileInput {
  nickname: string;
  expectedVersion: number;
}

export interface HomeFlowTaskEditInput extends HomeFlowTaskInput {
  expectedVersion: number;
}

interface HomeFlowPermissionInput {
  canPublishSchedule: boolean;
  expectedVersion: number;
}

interface HomeFlowCreateSpaceData {
  space: HomeFlowSpace;
  invitationCode: string;
  expiresAt: string;
}

interface HomeFlowJoinSpaceData {
  space: HomeFlowSpace;
}

export interface HomeFlowTaskDetailData {
  task: HomeFlowTask;
  availableActions: string[];
}

export class HomeFlowApi {
  private static readonly baseUrl: string = 'http://193.112.29.130/api/v1';
  static accessToken: string = '';
  static refreshToken: string = '';
  static accessExpiresAt: number = 0;
  static currentUser: HomeFlowUser | null = null;
  static currentSpace: HomeFlowSpace | null = null;
  private static taskRevisionCounter: number = 0;

  private static bumpTaskRevision(): void {
    HomeFlowApi.taskRevisionCounter += 1;
    AppStorage.setOrCreate('homeflowTaskRevision', 0);
    AppStorage.set('homeflowTaskRevision', HomeFlowApi.taskRevisionCounter);
  }

  static notifyTasksChanged(): void { HomeFlowApi.bumpTaskRevision(); }

  static async ensureAccessToken(): Promise<void> {
    if (HomeFlowApi.refreshToken.length > 0 && Date.now() >= HomeFlowApi.accessExpiresAt) {
      await HomeFlowApi.refresh();
    }
  }

  private static key(): string {
    return util.generateRandomUUID();
  }

  private static async sendEnvelope<T>(method: http.RequestMethod, path: string, payload: string = '',
    withKey: boolean = false, authorized: boolean = true): Promise<HomeFlowEnvelope<T>> {
    if (authorized && HomeFlowApi.refreshToken.length > 0 && Date.now() >= HomeFlowApi.accessExpiresAt) {
      await HomeFlowApi.refresh();
    }
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (authorized && HomeFlowApi.accessToken.length > 0) {
      headers['Authorization'] = 'Bearer ' + HomeFlowApi.accessToken;
    }
    if (withKey) {
      headers['Idempotency-Key'] = HomeFlowApi.key();
    }
    const client: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await client.request(HomeFlowApi.baseUrl + path, {
        method: method,
        header: headers,
        extraData: payload,
        expectDataType: http.HttpDataType.STRING,
        usingCache: false,
        usingProxy: false,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      const bodyText: string = response.result.toString();
      if (response.responseCode >= 200 && response.responseCode < 300) {
        if (response.responseCode === 204) {
          const empty: HomeFlowEnvelope<T> = { data: JSON.parse('null') as T };
          return empty;
        }
        const envelope: HomeFlowEnvelope<T> = JSON.parse(bodyText) as HomeFlowEnvelope<T>;
        return envelope;
      }
      const failure: HomeFlowErrorEnvelope = JSON.parse(bodyText) as HomeFlowErrorEnvelope;
      throw new Error(failure.error.message);
    } catch (error) {
      const requestError: Error = error as Error;
      throw new Error(requestError.message.length > 0 ? requestError.message : '网络请求失败，请稍后重试');
    } finally {
      client.destroy();
    }
  }

  private static async send<T>(method: http.RequestMethod, path: string, payload: string = '',
    withKey: boolean = false, authorized: boolean = true): Promise<T> {
    const envelope: HomeFlowEnvelope<T> = await HomeFlowApi.sendEnvelope<T>(
      method, path, payload, withKey, authorized);
    return envelope.data;
  }

  static async login(account: string, password: string): Promise<HomeFlowSpace | null> {
    const input: HomeFlowLoginInput = { account: account, password: password };
    const data: HomeFlowLoginData = await HomeFlowApi.send<HomeFlowLoginData>(http.RequestMethod.POST,
      '/auth/login', JSON.stringify(input), false, false);
    HomeFlowApi.accessToken = data.accessToken;
    HomeFlowApi.refreshToken = data.refreshToken;
    HomeFlowApi.accessExpiresAt = Date.now() + Math.max(0, data.expiresIn - 30) * 1000;
    HomeFlowApi.currentUser = data.user;
    HomeFlowApi.currentSpace = data.currentSpace;
    AppStorage.setOrCreate('homeflowNickname', data.user.nickname);
    AppStorage.set('homeflowNickname', data.user.nickname);
    return data.currentSpace;
  }

  static async register(account: string, password: string, nickname: string): Promise<void> {
    const input: HomeFlowRegisterInput = { account: account, password: password, nickname: nickname };
    await HomeFlowApi.send<HomeFlowUser>(http.RequestMethod.POST, '/auth/register',
      JSON.stringify(input), true, false);
  }

  static async refresh(): Promise<void> {
    if (HomeFlowApi.refreshToken.length === 0) {
      throw new Error('请重新登录');
    }
    const input: HomeFlowRefreshInput = { refreshToken: HomeFlowApi.refreshToken };
    const data: HomeFlowLoginData = await HomeFlowApi.send<HomeFlowLoginData>(http.RequestMethod.POST,
      '/auth/refresh', JSON.stringify(input), true, false);
    HomeFlowApi.accessToken = data.accessToken;
    HomeFlowApi.refreshToken = data.refreshToken;
    HomeFlowApi.accessExpiresAt = Date.now() + Math.max(0, data.expiresIn - 30) * 1000;
    HomeFlowApi.currentUser = data.user;
    HomeFlowApi.currentSpace = data.currentSpace;
    AppStorage.setOrCreate('homeflowNickname', data.user.nickname);
    AppStorage.set('homeflowNickname', data.user.nickname);
  }

  static async logout(): Promise<void> {
    try {
      if (HomeFlowApi.refreshToken.length > 0) {
        const input: HomeFlowRefreshInput = { refreshToken: HomeFlowApi.refreshToken };
        await HomeFlowApi.send<Object>(http.RequestMethod.POST, '/auth/logout',
          JSON.stringify(input), true, false);
      }
    } finally {
      HomeFlowApi.accessToken = '';
      HomeFlowApi.refreshToken = '';
      HomeFlowApi.accessExpiresAt = 0;
      HomeFlowApi.currentUser = null;
      HomeFlowApi.currentSpace = null;
      AppStorage.set('homeflowNickname', '');
    }
  }

  static async createSpace(name: string, scene: string): Promise<HomeFlowInvitation> {
    const input: HomeFlowSpaceInput = { name: name, scene: scene };
    const data: HomeFlowCreateSpaceData = await HomeFlowApi.send<HomeFlowCreateSpaceData>(http.RequestMethod.POST,
      '/spaces', JSON.stringify(input), true);
    HomeFlowApi.currentSpace = data.space;
    const invitation: HomeFlowInvitation = {
      invitationCode: data.invitationCode, expiresAt: data.expiresAt
    };
    return invitation;
  }

  static async me(): Promise<HomeFlowMe> {
    const data: HomeFlowMe = await HomeFlowApi.send<HomeFlowMe>(http.RequestMethod.GET, '/me');
    HomeFlowApi.currentUser = data.user;
    HomeFlowApi.currentSpace = data.currentSpace;
    AppStorage.setOrCreate('homeflowNickname', data.user.nickname);
    AppStorage.set('homeflowNickname', data.user.nickname);
    return data;
  }

  static async updateNickname(nickname: string, version: number): Promise<HomeFlowUser> {
    const input: HomeFlowProfileInput = { nickname: nickname, expectedVersion: version };
    await HomeFlowApi.ensureAccessToken();
    const user: HomeFlowUser = await HomeFlowPatch.request<HomeFlowUser>(
      HomeFlowApi.baseUrl + '/me', JSON.stringify(input), HomeFlowApi.accessToken);
    HomeFlowApi.currentUser = user;
    AppStorage.setOrCreate('homeflowNickname', user.nickname);
    AppStorage.set('homeflowNickname', user.nickname);
    return user;
  }

  static async members(): Promise<HomeFlowMember[]> {
    if (HomeFlowApi.currentSpace === null) { throw new Error('请先加入空间'); }
    return HomeFlowApi.send<HomeFlowMember[]>(http.RequestMethod.GET,
      '/spaces/' + HomeFlowApi.currentSpace.id + '/members?limit=100');
  }

  static async invitation(): Promise<HomeFlowInvitation> {
    if (HomeFlowApi.currentSpace === null) { throw new Error('请先加入空间'); }
    return HomeFlowApi.send<HomeFlowInvitation>(http.RequestMethod.GET,
      '/spaces/' + HomeFlowApi.currentSpace.id + '/invitation');
  }

  static async rotateInvitation(): Promise<HomeFlowInvitation> {
    if (HomeFlowApi.currentSpace === null) { throw new Error('请先加入空间'); }
    return HomeFlowApi.send<HomeFlowInvitation>(http.RequestMethod.POST,
      '/spaces/' + HomeFlowApi.currentSpace.id + '/invitation/rotate', '', true);
  }

  static async updatePermission(memberId: string, enabled: boolean, version: number): Promise<HomeFlowMember> {
    if (HomeFlowApi.currentSpace === null) { throw new Error('请先加入空间'); }
    const input: HomeFlowPermissionInput = { canPublishSchedule: enabled, expectedVersion: version };
    await HomeFlowApi.ensureAccessToken();
    return HomeFlowPatch.request<HomeFlowMember>(
      HomeFlowApi.baseUrl + '/spaces/' + HomeFlowApi.currentSpace.id +
      '/members/' + memberId + '/permissions', JSON.stringify(input), HomeFlowApi.accessToken);
  }

  static async joinSpace(invitationCode: string): Promise<void> {
    const input: HomeFlowJoinInput = { invitationCode: invitationCode };
    const data: HomeFlowJoinSpaceData = await HomeFlowApi.send<HomeFlowJoinSpaceData>(http.RequestMethod.POST,
      '/spaces/join', JSON.stringify(input), true);
    HomeFlowApi.currentSpace = data.space;
  }

  static async createTask(input: HomeFlowTaskInput): Promise<HomeFlowTask> {
    if (HomeFlowApi.currentSpace === null) {
      throw new Error('请先加入空间');
    }
    const task: HomeFlowTask = await HomeFlowApi.send<HomeFlowTask>(http.RequestMethod.POST,
      '/spaces/' + HomeFlowApi.currentSpace.id + '/tasks', JSON.stringify(input), true);
    HomeFlowApi.bumpTaskRevision();
    return task;
  }

  static async tasks(from: string, to: string): Promise<HomeFlowTask[]> {
    if (HomeFlowApi.currentSpace === null) {
      throw new Error('请先加入空间');
    }
    let collected: HomeFlowTask[] = [];
    let cursor: string | null = null;
    for (let page: number = 0; page < 100; page += 1) {
      let path: string = '/spaces/' + HomeFlowApi.currentSpace.id +
        '/tasks?from=' + from + '&to=' + to + '&limit=100';
      if (cursor !== null) { path += '&cursor=' + encodeURIComponent(cursor); }
      const envelope: HomeFlowEnvelope<HomeFlowTask[]> = await HomeFlowApi.sendEnvelope<HomeFlowTask[]>(
        http.RequestMethod.GET, path);
      collected = collected.concat(envelope.data);
      cursor = envelope.meta === undefined || envelope.meta.nextCursor === undefined ?
        null : envelope.meta.nextCursor;
      if (cursor === null) { return collected; }
    }
    throw new Error('任务数量较多，请缩小日期范围');
  }

  static async taskDetail(taskId: string): Promise<HomeFlowTaskDetailData> {
    return HomeFlowApi.send<HomeFlowTaskDetailData>(http.RequestMethod.GET, '/tasks/' + taskId);
  }

  static async cancelTask(taskId: string, version: number): Promise<void> {
    const input: HomeFlowCancelInput = { expectedVersion: version };
    await HomeFlowApi.send<HomeFlowTask>(http.RequestMethod.POST, '/tasks/' + taskId + '/cancel',
      JSON.stringify(input), true);
    HomeFlowApi.bumpTaskRevision();
  }

  static async updateTask(taskId: string, input: HomeFlowTaskEditInput): Promise<HomeFlowTask> {
    await HomeFlowApi.ensureAccessToken();
    const task: HomeFlowTask = await HomeFlowPatch.request<HomeFlowTask>(
      HomeFlowApi.baseUrl + '/tasks/' + taskId, JSON.stringify(input), HomeFlowApi.accessToken);
    HomeFlowApi.bumpTaskRevision();
    return task;
  }

  static async taskEvents(taskId: string): Promise<HomeFlowTaskEvent[]> {
    return HomeFlowApi.send<HomeFlowTaskEvent[]>(http.RequestMethod.GET,
      '/tasks/' + taskId + '/events?limit=100');
  }
}

