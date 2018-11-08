library lifecycle_flutter;

import 'package:flutter/material.dart';
import 'package:lifecycle_core/lifecycle_core.dart';

export 'package:lifecycle_core/lifecycle_core.dart';

/// 具有生命周期感知的State混入类，可以需要被混入
mixin StateWithLifeCycleMixin<T extends StatefulWidget> on State<T>
    implements LifecycleOwner, ViewModelStoreOwner {
  final _lifecycleRegistry = LifecycleRegistry();

  final _viewModelStore = ViewModelStore();

  @override
  Lifecycle get lifecycle => _lifecycleRegistry;

  @override
  ViewModelStore get viewModelStore => _viewModelStore;

  /// 获取本[StateWithLifeCycle]生命周期管理下的[ViewModel]实例
  ///
  /// * 由一个[provider]提供，在不同的[StateWithLifeCycle]中获取的[ViewModel]实例也不相同，
  /// 获取的[ViewModel]对象生命周期与本[StateWithLifeCycle]一至。
  /// * 本方法可以在[StateWithLifeCycle]存活时的任何时间调用，
  /// 且对与同类型[provider]实例总是返回相同[ViewModel]实例。
  R getLocalViewModel<R extends ViewModel>(ViewModelProvider<R> provider) =>
      getViewModel(this, provider);

  /// 获取根级[StateWithLifeCycle]生命周期管理下的[ViewModel]实例
  ///
  /// * 本方法会获取[Widget]树中从根级开始的第一个继承[StateWithLifeCycle]的[State]对象所管理的[ViewModel]。
  /// * 多个子节点[StateWithLifeCycle]可以通过此方式共享本[Widget]树下的[ViewModel]实例，
  /// 也就是说，如果多个子[StateWithLifeCycle]需要共享同一个[ViewModel]那么他们必须有一个共同的父[State]，
  /// 并且该父[State]需要继承或混入[StateWithLifeCycle]，否则会返回null。
  /// * 该方法依赖[BuildContext]对象，因此该方法必须在[initState]之后调用，否则返回null。
  /// * 如果本[StateWithLifeCycle]对象会在不同的[Widget]树中装卸，
  /// 则在[didChangeDependencies]中需要重新调用该方法将以获取的
  /// [ViewModel]引用换为新根级[StateWithLifeCycle]所管理的[ViewModel]实例，
  /// 否则使用旧的[ViewModel]可能造成功能错乱或内存泄漏。
  /// * 该方法使用[BuildContext.rootAncestorStateOfType]获取根节点，因此该方法时间复杂度为O(N)。
  R getRootViewModel<R extends ViewModel>(ViewModelProvider<R> provider) {
    if (context == null) {
      return null;
    }

    var state =
        context.rootAncestorStateOfType(TypeMatcher<StateWithLifeCycleMixin>());

    if (state is StateWithLifeCycleMixin) {
      return state.getLocalViewModel(provider);
    } else {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.onCreate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.onResume);
  }

  @override
  void dispose() {
    super.dispose();
    _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.onDestroy);
    _viewModelStore.clear();
  }
}

/// 具有生命周期感知的State抽象类，需要被继承
abstract class StateWithLifeCycle<T extends StatefulWidget> extends State<T>
    with StateWithLifeCycleMixin {}
