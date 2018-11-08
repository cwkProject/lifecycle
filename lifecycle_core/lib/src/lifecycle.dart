// Created by 超悟空 on 2018/9/12.
// Version 1.0 2018/9/12
// Since 1.0 2018/9/12
import 'package:meta/meta.dart';

typedef VoidCallback = void Function();

/// 生命周期组件，具有UI生命周期事件和状态
///
/// 通过注入具有生命周期的UI组件来感知对应的生命周期事件，
/// 可以通过添加监听器来获取生命周期事件
abstract class Lifecycle {
  /// 添加生命周期观察者
  ///
  /// * 添加[LifecycleObserver]观察者并为[observer]提供[LifecycleOwner]的当前生命周期事件。
  /// * [observer]会接收到完整的事件，比如当前[LifecycleOwner]处于[LifecycleState.resumed]，
  /// 则[observer]会收到[LifecycleEvent.onCreate]和[LifecycleEvent.onResume]事件。
  /// * 如果生命周期当前处于[LifecycleState.destroyed]状态，则本次添加会被忽略
  void addObserver(LifecycleObserver observer);

  /// 移除生命周期观察者
  ///
  /// 移除[observer]，如过在生命周期同步过程中移除并且[observer]还未收到事件，则它不会再收到事件。
  void removeObserver(LifecycleObserver observer);

  /// 当前生命周期状态
  LifecycleState get currentState;
}

/// 组件生命周期监听器
///
/// #生命周期流程
///
/// ```
///
/// onCreate
///
///    ↓
///
/// onResume
///
///    ↓ ↑
///
/// onPause
///
///    ↓
///
/// onDestroy
///
/// ```
class LifecycleObserver {
  /// 组件初始化生命周期回调
  final VoidCallback _onCreate;

  /// 组件加载完成前台显示生命周期
  final VoidCallback _onResume;

  /// 组件分离转入后台生命周期
  final VoidCallback _onPause;

  /// 组件销毁生命周期
  final VoidCallback _onDestroy;

  /// 新建一个生命周期监听器
  ///
  /// 可选参数为各种生命周期事件回调
  /// * see [LifecycleObserver.onCreate],[LifecycleObserver.onResume],[LifecycleObserver.onPause],[LifecycleObserver.onDestroy]
  const LifecycleObserver(
      {VoidCallback onCreate = null,
      VoidCallback onResume = null,
      VoidCallback onPause = null,
      VoidCallback onDestroy = null})
      : _onCreate = onCreate,
        _onResume = onResume,
        _onPause = onPause,
        _onDestroy = onDestroy;

  /// 组件初始化生命周期
  ///
  /// * 对应[LifecycleEvent.onCreate]
  /// * 当[LifecycleOwner]初始化时执行，组件只执行一次该事件。
  /// * 在这里应该是初始化数据和监听器的好地方
  @protected
  void onCreate() {
    if (_onCreate != null) {
      _onCreate();
    }
  }

  /// 组件加载完成前台显示生命周期
  ///
  /// * 对应[LifecycleEvent.onResume]
  /// * 在[onCreate]之后，当[LifecycleOwner]被附加到UI树中或者变为前台显示时被调用，该生命周期可能会执行多次，
  /// 每当[LifecycleOwner]被重新附加到UI树中或者由后台转入前台时被调用一次，组件可能由于[onPause]被分离出UI树或暂时转到后台
  @protected
  void onResume() {
    if (_onResume != null) {
      _onResume();
    }
  }

  /// 组件分离转入后台生命周期
  ///
  /// * 对应[LifecycleEvent.onPause]
  /// * 在[LifecycleOwner]执行[onResume]后组件处于前台，之后UI可能会分离或隐藏[LifecycleOwner]，此时会执行该生命周期，
  /// 该方法总是和[onResume]对应
  @protected
  void onPause() {
    if (_onPause != null) {
      _onPause();
    }
  }

  /// 组件销毁生命周期
  ///
  /// * 对应[LifecycleEvent.onDestroy]
  /// * 当[LifecycleOwner]将要销毁时执行，组件只执行一次该事件，且执行后组件将不存在且不可逆。
  /// * 在这里应该清理数据和注销监听器
  @protected
  void onDestroy() {
    if (_onDestroy != null) {
      _onDestroy();
    }
  }
}

/// 用于mixin的特定[LifecycleObserver]实现
mixin LifecycleObserverMixin implements LifecycleObserver {
  @override
  void onCreate() {}

  @override
  void onDestroy() {}

  @override
  void onPause() {}

  @override
  void onResume() {}
}

/// 具有生命周期的类，组件可以获取生命周期
///
/// 生命周期对象应该挂钩[LifecycleEvent]中的生命周期事件
abstract class LifecycleOwner {
  /// 获取这个类的[Lifecycle]
  Lifecycle get lifecycle;
}

/// [LifecycleOwner]的生命周期事件
enum LifecycleEvent {
  /// [LifecycleOwner]的初始化事件
  onCreate,

  /// [LifecycleOwner]的前台显示事件
  onResume,

  /// [LifecycleOwner]的移除或转入后台事件
  onPause,

  /// [LifecycleOwner]被销毁时的事件
  onDestroy,
}

/// [LifecycleOwner]的生命周期状态
enum LifecycleState {
  /// 已销毁状态
  ///
  /// * [LifecycleOwner]已执行过[LifecycleEvent.onDestroy]事件
  /// * 该状态不可逆
  destroyed,

  /// 初始状态
  ///
  /// * [LifecycleOwner]对象创建但为执行初始化事件[LifecycleEvent.onCreate]
  /// * 该状态不可逆
  initialized,

  /// 已创建状态
  ///
  /// [LifecycleOwner]执行过初始化事件[LifecycleEvent.onCreate]，
  /// 但是未执行[LifecycleEvent.onResume]或者后续执行了[LifecycleEvent.onPause]时组件会处于该状态
  created,

  /// 已显示状态
  ///
  /// [LifecycleOwner]执行过[LifecycleEvent.onResume]，
  /// 但未执行[LifecycleEvent.onPause]的状态
  resumed
}

/// 一个[Lifecycle]的实现
///
/// 应该由具有生命周期的类使用，即被[LifecycleOwner]的子类所拥有，
/// 用于管理复数个[LifecycleObserver]
class LifecycleRegistry extends Lifecycle {
  /// 观察者集合，<观察者，当前状态>
  final _observers = List<_ObserverWithState>();

  /// 观察者缓冲集合，用于缓冲在生命周期事件同步时发生的[addObserver]和[removeObserver]操作
  final _observerCache = Map<LifecycleObserver, _ObserverWithState>();

  /// 当前状态
  var _state = LifecycleState.initialized;

  /// 表示是否正在处理生命周期事件同步
  var _handlingEvent = false;

  /// 处理生命周期事件
  ///
  /// 设置[currentState]并通知观察者，
  /// 如果本次事件到达的状态与[currentState]相同，则忽略本次事件，
  /// 如果[currentState]已到达[LifecycleState.destroyed]则忽略后续所有事件
  void handleLifecycleEvent(LifecycleEvent event) {
    if (_state == LifecycleState.destroyed) {
      // 不可逆
      return;
    }

    final next = _getStateAfter(event);
    if (_state == next) {
      return;
    }
    _state = next;
    _sync();

    if (_state == LifecycleState.destroyed) {
      _observers.clear();
    }
  }

  /// 执行生命周期事件同步
  ///
  /// 同步观察者生命周期状态，
  /// 如果同步过程中观察者集合结构发生变化，
  /// 即调用了[addObserver]或[removeObserver]则在本方法中做循环延迟同步，直至全部观察者同步完成
  void _sync() {
    _handlingEvent = true;

    if (!_isSynced()) {
      _observers.forEach(_move);
    }

    if (_observerCache.isNotEmpty) {
      _fill();
      _sync();
    }

    _handlingEvent = false;
  }

  /// 当前状态是否是同步的
  bool _isSynced() {
    if (_observers.isEmpty) {
      return true;
    }

    var eldestObserverState = _observers.first._state;
    var newestObserverState = _observers.last._state;

    return eldestObserverState == newestObserverState &&
        _state == newestObserverState;
  }

  /// 移动[observer]状态并通知事件
  void _move(_ObserverWithState observer) {
    while (observer._isActive && observer._state != _state) {
      if (_state.index > observer._state.index) {
        observer._dispatchEvent(_forwardEvent(observer._state));
      } else if (_state.index < observer._state.index) {
        observer._dispatchEvent(_backwardEvent(observer._state));
      }
    }
  }

  /// 消费缓冲观察者
  void _fill() {
    _observerCache.forEach((observer, observerWithState) {
      _observers.removeWhere((_) => _._observer == observer);
      if (observerWithState._isActive) {
        _observers.add(observerWithState);
      }
    });
    _observerCache.clear();
  }

  @override
  void addObserver(LifecycleObserver observer) {
    if (_state == LifecycleState.destroyed) {
      // 生命周期已结束，不再接收观察者
      return;
    }

    var observerWithState = _observers
        .firstWhere((_) => _._observer == observer, orElse: () => null);

    if (observerWithState != null && observerWithState._isActive) {
      // 已存在
      return;
    }

    observerWithState = observerWithState ?? _ObserverWithState(observer);

    observerWithState._isActive = true;

    if (_handlingEvent) {
      _observerCache[observer] = observerWithState;
    } else {
      _observers.add(observerWithState);
      _sync();
    }
  }

  @override
  void removeObserver(LifecycleObserver observer) {
    if (!_handlingEvent) {
      _observers.removeWhere((_) => _._observer == observer);
    } else {
      var observerWithState = _observers
          .firstWhere((_) => _._observer == observer, orElse: () => null);

      if (observerWithState != null) {
        observerWithState._isActive = false;
        _observerCache[observer] = observerWithState;
      } else {
        _observerCache.remove(observer);
      }
    }
  }

  @override
  LifecycleState get currentState => _state;
}

/// 获取下一个状态
///
/// 根据本次[event]来确定生命周期对象到达的下一个状态
LifecycleState _getStateAfter(LifecycleEvent event) {
  switch (event) {
    case LifecycleEvent.onCreate:
    case LifecycleEvent.onPause:
      return LifecycleState.created;
    case LifecycleEvent.onResume:
      return LifecycleState.resumed;
    case LifecycleEvent.onDestroy:
      return LifecycleState.destroyed;
  }
  throw ArgumentError("Unexpected event value $event");
}

/// 推进事件
///
/// 通过当前[state]获取目标[LifecycleObserver]到达下一个状态应该执行的事件
LifecycleEvent _forwardEvent(LifecycleState state) {
  switch (state) {
    case LifecycleState.initialized:
      return LifecycleEvent.onCreate;
    case LifecycleState.created:
      return LifecycleEvent.onResume;
    default:
      throw ArgumentError("Unexpected state value $state");
  }
}

/// 回滚事件
///
/// 通过当前[state]获取目标[LifecycleObserver]到达上一个状态应该执行的事件
LifecycleEvent _backwardEvent(LifecycleState state) {
  switch (state) {
    case LifecycleState.created:
      return LifecycleEvent.onDestroy;
    case LifecycleState.resumed:
      return LifecycleEvent.onPause;
    default:
      throw ArgumentError("Unexpected state value $state");
  }
}

/// 观察者装饰类，包括观察者当前状态
class _ObserverWithState {
  /// 观察者
  final LifecycleObserver _observer;

  /// 当前生命周期状态
  LifecycleState _state = LifecycleState.initialized;

  /// 表示该观察者是否处于活动监听状态，false时表示将要删除
  bool _isActive = true;

  /// 创建一个[_observer]的装饰类
  _ObserverWithState(this._observer);

  /// 调度事件
  ///
  /// 通知本观察者执行[event]并到达下一个状态
  void _dispatchEvent(LifecycleEvent event) {
    var newState = _getStateAfter(event);
    switch (event) {
      case LifecycleEvent.onCreate:
        _observer.onCreate();
        break;
      case LifecycleEvent.onResume:
        _observer.onResume();
        break;
      case LifecycleEvent.onPause:
        _observer.onPause();
        break;
      case LifecycleEvent.onDestroy:
        _observer.onDestroy();
        break;
      default:
        throw ArgumentError("Unexpected event value $event");
    }
    _state = newState;
  }
}
