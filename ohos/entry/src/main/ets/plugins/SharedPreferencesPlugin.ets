import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import { FlutterPlugin, FlutterPluginBinding, Log, MethodCall, MethodCallHandler, MethodChannel, MethodResult } from '@ohos/flutter_ohos';

const TAG = 'SharedPreferencesPlugin';
const CHANNEL_NAME = 'plugins.flutter.io/shared_preferences';
const STORE_NAME = 'FlutterSharedPreferences';
const STORE_KEY = '__flutter_shared_preferences_json__';

type JsonValue = null | boolean | number | string | JsonValue[] | { [key: string]: JsonValue };

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value == null || typeof value !== 'object') return null;
  if (value instanceof Array) return null;
  return value as Record<string, unknown>;
}

function parseJsonObject(text: string): Record<string, JsonValue> {
  try {
    const parsed = JSON.parse(text);
    if (parsed == null || typeof parsed !== 'object' || parsed instanceof Array) return {};
    return parsed as Record<string, JsonValue>;
  } catch (_) {
    return {};
  }
}

export default class SharedPreferencesPlugin implements FlutterPlugin {
  private channel: MethodChannel | null = null;
  private context: common.Context | null = null;
  private prefs: preferences.Preferences | null = null;
  private initializingPrefs: Promise<preferences.Preferences> | null = null;

  getUniqueClassName(): string {
    return TAG;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.context = binding.getApplicationContext();
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(new SharedPreferencesHandler(this));
  }

  onDetachedFromEngine(_binding: FlutterPluginBinding): void {
    if (this.channel) {
      this.channel.setMethodCallHandler(null);
    }
    this.channel = null;
    this.context = null;
    this.prefs = null;
    this.initializingPrefs = null;
  }

  private async ensurePrefs(): Promise<preferences.Preferences> {
    if (this.prefs) return this.prefs;
    if (!this.initializingPrefs) {
      if (!this.context) {
        throw new Error('Context is not available');
      }
      this.initializingPrefs = preferences.getPreferences(this.context, STORE_NAME).then((p) => {
        this.prefs = p;
        return p;
      }).finally(() => {
        this.initializingPrefs = null;
      });
    }
    return this.initializingPrefs;
  }

  async getAll(): Promise<Record<string, JsonValue>> {
    const prefs = await this.ensurePrefs();
    const raw = await prefs.get(STORE_KEY, '{}') as string;
    return parseJsonObject(raw);
  }

  async setAll(map: Record<string, JsonValue>): Promise<void> {
    const prefs = await this.ensurePrefs();
    await prefs.put(STORE_KEY, JSON.stringify(map));
    await prefs.flush();
  }

  async setValue(key: string, value: JsonValue): Promise<void> {
    const all = await this.getAll();
    all[key] = value;
    await this.setAll(all);
  }

  async remove(key: string): Promise<void> {
    const all = await this.getAll();
    delete all[key];
    await this.setAll(all);
  }

  async clear(): Promise<void> {
    await this.setAll({});
  }
}

class SharedPreferencesHandler implements MethodCallHandler {
  private plugin: SharedPreferencesPlugin;

  constructor(plugin: SharedPreferencesPlugin) {
    this.plugin = plugin;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.handle(call, result);
  }

  private async handle(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      switch (call.method) {
        case 'getAll': {
          const all = await this.plugin.getAll();
          result.success(all as unknown as JsonValue);
          return;
        }
        case 'setBool':
        case 'setInt':
        case 'setDouble':
        case 'setString':
        case 'setStringList': {
          const args = asRecord(call.arguments);
          const key = typeof args?.key === 'string' ? args.key : (typeof args?.['key'] === 'string' ? args['key'] as string : null);
          const value = args?.value ?? args?.['value'];
          if (!key) {
            result.error('invalid_args', 'Missing key', null);
            return;
          }
          await this.plugin.setValue(key, value as JsonValue);
          result.success(true);
          return;
        }
        case 'remove': {
          const args = call.arguments;
          const key = typeof args === 'string' ? args : (typeof asRecord(args)?.key === 'string' ? asRecord(args)!.key as string : null);
          if (!key) {
            result.error('invalid_args', 'Missing key', null);
            return;
          }
          await this.plugin.remove(key);
          result.success(true);
          return;
        }
        case 'clear': {
          await this.plugin.clear();
          result.success(true);
          return;
        }
        case 'commit': {
          result.success(true);
          return;
        }
        default: {
          result.notImplemented();
          return;
        }
      }
    } catch (e) {
      Log.e(TAG, 'SharedPreferences call failed', e);
      result.error('error', 'SharedPreferences call failed', null);
    }
  }
}
