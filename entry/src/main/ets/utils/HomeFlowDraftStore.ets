export interface HomeFlowLocalDraft {
  id: string;
  title: string;
  content: string;
  tone: number;
  savedAt: string;
}

export class HomeFlowDraftStore {
  private static items: HomeFlowLocalDraft[] = [];
  private static serial: number = 0;

  static all(): HomeFlowLocalDraft[] { return HomeFlowDraftStore.items.slice(); }

  static save(title: string, content: string, tone: number, id: string = ''): HomeFlowLocalDraft {
    const trimmed: string = content.trim();
    if (trimmed.length === 0) { throw new Error('草稿内容不能为空'); }
    if (id.length > 0) {
      const existing: HomeFlowLocalDraft | undefined = HomeFlowDraftStore.items.find(
        (item: HomeFlowLocalDraft): boolean => item.id === id);
      if (existing !== undefined) {
        existing.title = title.trim().length > 0 ? title.trim() : '未命名草稿';
        existing.content = trimmed;
        existing.tone = tone;
        existing.savedAt = new Date().toISOString();
        return existing;
      }
    }
    HomeFlowDraftStore.serial += 1;
    const draft: HomeFlowLocalDraft = {
      id: Date.now().toString() + '-' + HomeFlowDraftStore.serial.toString(),
      title: title.trim().length > 0 ? title.trim() : '未命名草稿',
      content: trimmed,
      tone: tone,
      savedAt: new Date().toISOString()
    };
    HomeFlowDraftStore.items.unshift(draft);
    return draft;
  }

  static remove(id: string): void {
    HomeFlowDraftStore.items = HomeFlowDraftStore.items.filter(
      (item: HomeFlowLocalDraft): boolean => item.id !== id);
  }

  static clear(): void { HomeFlowDraftStore.items = []; }
}
