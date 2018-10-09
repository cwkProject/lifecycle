// Created by 超悟空 on 2018/9/14.
// Version 1.0 2018/9/14
// Since 1.0 2018/9/14

import 'package:meta/meta.dart';

/// 负责准备与管理数据的类
///
/// * [ViewModel]与绑定的ui界面的生命周期一致甚至更长，
/// 只有当ui界面彻底销毁不再使用时[ViewModel]才会执行[onCleared]方法并销毁。
/// * [ViewModel]应该同[ViewModelProvider]配合使用，由[ViewModelProvider]负责创建[ViewModel]，
/// 在ui组件中不能跳过[ViewModelProvider]直接创建[ViewModel]，否则[ViewModel]将无法被正确管理。
/// * [ViewModel]实质上由[ViewModelStore]负责保存和管理。
/// * 最终用户会使用[getViewModel]来获取一个[ViewModel]，通过交给[getViewModel]一个[ViewModelStoreOwner]的方式创建和管理这个[ViewModel]
abstract class ViewModel {
  /// [ViewModel]将要销毁前执行，在这里可以清理数据和注销监听器
  @protected
  void onCleared() {}
}

/// [ViewModel]提供者
///
/// 用于创建[ViewModel]同[ViewModel]配对使用，
/// 对于同一个[ViewModelStore]有且仅有一次[createViewModel]调用，
/// 即对于绑定的[ViewModelStoreOwner]或[ViewModelStore]仅会创建唯一一个[ViewModel]实例
abstract class ViewModelProvider<T extends ViewModel> {
  const ViewModelProvider();

  /// 创建一个[T]类型的[ViewModel]子类实例
  @protected
  T createViewModel();
}

/// [ViewModelStore]拥有者
///
/// 保存有[ViewModelStore]的实例，并且可以给[getViewModel]提供这个[ViewModelStore]实例
abstract class ViewModelStoreOwner {
  /// 获取[ViewModelStore]的实例
  @protected
  ViewModelStore get viewModelStore;
}

/// [ViewModel]管理类
///
/// 实际负责存储和管理[ViewModel]实例对象的管理器，
/// 通过保存[ViewModelProvider]和[ViewModel]的映射关系来维护[ViewModel]和它的唯一性
class ViewModelStore {
  /// [ViewModel]映射表
  final _map = Map<Type, ViewModel>();

  /// 使用[key]保存一个[ViewModel]
  void _put(Type key, ViewModel viewModel) {
    ViewModel oldViewModel = _map[key];
    if (oldViewModel != null) {
      oldViewModel.onCleared();
    }
    _map[key] = viewModel;
  }

  /// 获取一个[ViewModel]
  ViewModel _get(Type key) {
    return _map[key];
  }

  /// 清空[ViewModel]并执行[ViewModel.onCleared]
  ///
  /// 应该在[ViewModelStoreOwner]的生命周期结束时调用该方法
  void clear() {
    _map.forEach((_, viewModel) {
      viewModel.onCleared();
    });

    _map.clear();
  }
}

/// 获取[ViewModel]实例
///
/// 通过给定的[owner]和[provider]来获取[T]实例，
/// 如果[owner]中已有[T]类型的实例，则会直接返回该实例，
/// 如果[owner]中不存在[T]类型的实例，则会先使用[provider]创建[T]实例并保存。
T getViewModel<T extends ViewModel>(
    ViewModelStoreOwner owner, ViewModelProvider<T> provider) {
  var viewModel = owner.viewModelStore._get(provider.runtimeType);

  if (viewModel is T) {
    return viewModel;
  }

  viewModel = provider.createViewModel();

  owner.viewModelStore._put(provider.runtimeType, viewModel);

  return viewModel;
}
