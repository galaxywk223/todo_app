import common from '@ohos.app.ability.common';
import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodCallHandler, MethodChannel, MethodResult } from '@ohos/flutter_ohos';

const TAG = 'PathProviderPlugin';
const CHANNEL_NAME = 'plugins.flutter.io/path_provider';

export default class PathProviderPlugin implements FlutterPlugin {
  private channel: MethodChannel | null = null;
  private context: common.Context | null = null;

  getUniqueClassName(): string {
    return TAG;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.context = binding.getApplicationContext();
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(new PathProviderHandler(this));
  }

  onDetachedFromEngine(_binding: FlutterPluginBinding): void {
    if (this.channel) {
      this.channel.setMethodCallHandler(null);
    }
    this.channel = null;
    this.context = null;
  }

  getFilesDir(): string {
    if (!this.context) throw new Error('Context is not available');
    return this.context.filesDir;
  }

  getCacheDir(): string {
    if (!this.context) throw new Error('Context is not available');
    return this.context.cacheDir;
  }
}

class PathProviderHandler implements MethodCallHandler {
  private plugin: PathProviderPlugin;

  constructor(plugin: PathProviderPlugin) {
    this.plugin = plugin;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    try {
      switch (call.method) {
        case 'getApplicationDocumentsDirectory':
        case 'getApplicationSupportDirectory':
        case 'getLibraryDirectory': {
          result.success(this.plugin.getFilesDir());
          return;
        }
        case 'getTemporaryDirectory':
        case 'getApplicationCacheDirectory': {
          result.success(this.plugin.getCacheDir());
          return;
        }
        case 'getDownloadsDirectory': {
          result.success(this.plugin.getFilesDir());
          return;
        }
        default: {
          result.notImplemented();
          return;
        }
      }
    } catch (_) {
      result.error('error', 'Path provider call failed', null);
    }
  }
}
