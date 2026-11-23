import { rcp } from '@kit.RemoteCommunicationKit';

interface HomeFlowPatchEnvelope<T> { data: T; }
interface HomeFlowPatchError { message: string; }
interface HomeFlowPatchFailure { error: HomeFlowPatchError; }

export class HomeFlowPatch {
  static async request<T>(url: string, payload: string, accessToken: string): Promise<T> {
    const headers: rcp.RequestHeaders = {
      'content-type': 'application/json',
      'authorization': 'Bearer ' + accessToken
    };
    const session: rcp.Session = rcp.createSession();
    try {
      const request: rcp.Request = new rcp.Request(url, 'PATCH', headers, payload);
      const response: rcp.Response = await session.fetch(request);
      const body: string = response.toString() ?? '';
      if (response.statusCode >= 200 && response.statusCode < 300) {
        const envelope: HomeFlowPatchEnvelope<T> = JSON.parse(body) as HomeFlowPatchEnvelope<T>;
        return envelope.data;
      }
      const failure: HomeFlowPatchFailure = JSON.parse(body) as HomeFlowPatchFailure;
      throw new Error(failure.error.message);
    } finally {
      session.close();
    }
  }
}
