// Created by 超悟空 on 2018/9/17.
// Version 1.0 2018/9/17
// Since 1.0 2018/9/17

import 'dart:async';
import 'package:meta/meta.dart';

import 'lifecycle.dart';

/// 初始数据版本
const _startVersion = -1;

/// 数据持有者类，可以在给定的生命周期内观察到
///
/// * 可以通过[of]来生成一个广播流[Stream]，
/// 多次使用同一个[LifecycleOwner]会生成多个[Stream]实例。
/// * 当[LifecycleOwner]处于活动状态时(即[LifecycleState.resumed]时)，
/// 并且返回的广播流[Stream]有至少一个监听器的时候会开始通知数据变化。
/// * 当[LiveData]被赋值后，所有的活动监听器将收到这次变化，
/// 当[LiveData]已经被赋过一次值后，任何新生成的[Stream]在处于活动状态时都会再次收到最新的数据变化。
/// * [LifecycleOwner]由活动状态转变为非活动状态(即[LifecycleState.created]时)时会自动停止新数据变化的通知，
/// 当[LifecycleOwner]再次变为活动状态时会继续接收数据变化通知。
/// * [LiveData]会自动释放生命周期转变为[LifecycleState.destroyed]的[LifecycleOwner]引用和关闭与之关联的[Stream]。
/// * 关联的[LifecycleOwner]会自动释放(当生命周期转变为[LifecycleState.destroyed]时)，
/// 所以您不必手动管理移除和担心内存泄漏。
abstract class LiveData<T> {
  /// 流控制器，用于通知数据变化，每次数据变化会发射新版本号
  final _controller = StreamController.broadcast<int>();

  /// 用于独立于生命周期对象监听数据的流控制器
  final _foreverController = StreamController.broadcast<T>();

  /// 当前版本
  var _version = _startVersion;

  /// 是否第一次被监听
  var _isFirst = true;

  /// 当前保存的数据
  T _value = null;

  /// 当前的数据
  T get value => _value;

  /// 当前数据版本
  int get version => _version;

  /// 获取永续的数据流对象
  ///
  /// 使用此对象监听数据改变，无视生命周期变化。
  Stream<T> get foreverStream => _foreverController.stream;

  /// 获取一个数据流对象用于监听[LiveData]数据变化
  ///
  /// 创建一个绑定[owner]生命周期的广播流，
  /// 流的活动周期与[owner]生命周期同步，
  /// 当[owner]生命周期变为[LifecycleState.resumed]时开始发送数据变化，
  /// 当[owner]生命周期变为[LifecycleState.created]时暂停发送数据变化，
  /// 当[owner]生命周期变为[LifecycleState.destroyed]时关闭广播流并清理内部引用释放资源。
  Stream<T> of(LifecycleOwner owner) {
    if (_isFirst) {
      _controller.onListen = onActive;
      _controller.onCancel = onInactive;
    }

    var observer = _LifecycleBoundObserver<T>(this);

    owner.lifecycle.addObserver(observer);

    return observer.stream;
  }

  /// 当活动观察者从0变为1时调用
  ///
  /// 当监听[LiveData]的观察者中出现第一个活动观察者时被调用一次，
  /// 同时[hasActiveObserves]返回true
  @protected
  void onActive() {}

  /// 当活动观察者从1变为0时调用
  ///
  /// 当监听[LiveData]的观察者从有变为无或者所有活动的观察者状态变为非活动时被调用一次，
  /// 同时[hasActiveObserves]返回false
  @protected
  void onInactive() {}

  /// 是否存在活动的观察者，活动观察者指观察者生命周期处于[LifecycleState.resumed]并且[Stream]存在至少一个监听者
  bool get hasActiveObserves => _controller.hasListener;
}

/// 用于监听与[LiveData]相关联的[LifecycleOwner]的生命周期
class _LifecycleBoundObserver<T> extends LifecycleObserver {
  /// 关联的[LiveData]
  final LiveData<T> liveData;

  /// 本[LifecycleObserver]的数据版本
  var _lastVersion = _startVersion;

  /// 本[LifecycleObserver]是否处于活动状态，
  ///
  /// 活动状态指[_owner]生命周期状态处于[LifecycleState.resumed]
  var _active = false;

  /// 流控制器
  final StreamController<T> _controller = StreamController.broadcast();

  /// 用于监听[liveData]数据广播的流控制器
  StreamSubscription<int> _subscription;

  _LifecycleBoundObserver(this.liveData) {
    _controller.onListen = _onListen;
    _controller.onCancel = _onCancel;
  }

  /// 获取stream
  Stream<T> get stream => _controller.stream;

  /// [stream]首次被监听
  void _onListen() {
    _onStateChange();
  }

  /// [stream]被关闭或取消监听
  void _onCancel() {
    _onStateChange();
  }

  /// 活动或监听状态发生改变
  void _onStateChange() {
    if (_active && _controller.hasListener) {
      if (_subscription == null) {
        _subscription = liveData._controller.stream.listen(_considerNotify);
      }

      _considerNotify();
    } else {
      if (_subscription != null) {
        _subscription.cancel();
        _subscription = null;
      }
    }
  }

  /// 通知数据改变
  void _considerNotify([int newVersion]) {
    if (!_active || !_controller.hasListener) {
      return;
    }

    if (_lastVersion >= liveData._version) {
      return;
    }
    _lastVersion = liveData._version;

    _controller.add(liveData._value);
  }

  @override
  void onResume() {
    _active = true;
    _onStateChange();
  }

  @override
  void onPause() {
    _active = false;
    _onStateChange();
  }

  @override
  void onDestroy() {
    _active = false;

    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }

    _controller.close();
  }
}

/// [LiveData]公开子类
///
/// 客户端应该直接使用或继承此类来使用[LiveData]功能
class MutableLiveData<T> extends LiveData<T> {
  /// 给当前数据赋值
  set value(T value) {
    _value = value;
    _version++;
    _controller.add(version);
    _foreverController.add(value);
  }
}
