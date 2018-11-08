# lifecycle_core

[![pub package](https://img.shields.io/pub/v/lifecycle_core.svg)](https://pub.dartlang.org/packages/lifecycle_core)

模仿Android Lifecycle组件功能的dart版本生命周期核心组件

## Usage
* 添加 `lifecycle_core` 到 [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).
* `import 'package:lifecycle_core/lifecycle_core.dart';`

`LifecycleOwner`用于管理生命周期，需要由具有生命周期的对象实现，在flutter中这应该是`State`类。

`ViewModelStoreOwner`用于管理`ViewModel`，同样具有生命周期感知能力，建议由`LifecycleOwner`对象实现。

在`ViewModel`中可以管理数据和执行业务相关操作，由`ViewModelStoreOwner`管理，
每个`ViewModelStoreOwner`实例中可以管理多个不同类型的`ViewModel`实例，对于相同类型的`ViewModel`只会有一个实例。
在不同的`ViewModelStoreOwner`实例中同类型的`ViewModel`各自管理不同的实例。

`ViewModel`通过`getViewModel`方法获取，需要提供一个`ViewModelStoreOwner`实例和`ViewModelProvider`实例。

`ViewModelProvider`与`ViewModel`一一对应，同一个类型的`ViewModel`应该有且仅有一个对应的`ViewModelProvider`，
`ViewModelProvider`仅用于首次构建`ViewModel`实例使用。

* `ChangeObservable`特化的`LiveData`，仅用于通知事件的发生，比如一些数据发生了改变，这在flutter中特别有用。
通常`Widget`直接绑定了`ViewModel`中的一些变量，当数据发生变化时我们仅仅希望通知UI刷新而已，
此时已经不需要关心是那些数据发生了怎样的变化。

通过`LifecycleObserver`可以实现具有生命周期感知的功能组件，用法请看以下示例。

通过`LiveData`可以监听数据的变化，用法请看以下示例。

对于flutter的实现版本请查看 [lifecycle_flutter](https://github.com/cwkProject/lifecycle/tree/master/lifecycle_flutter)


## 生命周期注入

``` dart

/// 拥有生命周期的类，在flutter中，它应该是State类
///
/// [LifecycleOwner]负责管理生命周期，[ViewModelStoreOwner]负责管理[ViewModel]
class TestLifecycleOwner implements LifecycleOwner , ViewModelStoreOwner {

  /// 正真管理生命周期事件分发
  final _lifecycleRegistry = LifecycleRegistry();

  /// 正真管理[ViewModel]
  final _viewModelStore = ViewModelStore();

  @override
  Lifecycle get lifecycle => _lifecycleRegistry;

  @override
  ViewModelStore get viewModelStore => _viewModelStore;

  // 假设为生命周期开始
  create() {
    print("TestLifecycleOwner create");
    _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.onCreate);
  }

  // 假设为生命周期处于前台或附加到UI树中
  resume() {
    print("TestLifecycleOwner resume");
    _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.onResume);
  }

  // 假设为生命周期处于后台或从UI树种移除
  pause() {
    print("TestLifecycleOwner pause");
    _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.onPause);
  }

  // 假设为生命周期结束
  destroy() {
    print("TestLifecycleOwner destroy");
    _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.onDestroy);

    // 清理ViewModel
    _viewModelStore.clear();
  }
}

```

## Lifecycle

``` dart

/// 继承方式生命周期监听器
class ExtendsLifecycleObserver extends LifecycleObserver {
  @override
  onCreate() {
    print("ExtendsLifecycleObserver onCreate");
  }

  @override
  onPause() {
    print("ExtendsLifecycleObserver onPause");
  }

  @override
  onResume() {
    print("ExtendsLifecycleObserver onResume");
  }
}

/// 完整实现方式生命周期监听器
class ImplementsLifecycleObserver implements LifecycleObserver {
  @override
  onCreate() {
    print("ImplementsLifecycleObserver onCreate");
  }

  @override
  onPause() {
    print("ImplementsLifecycleObserver onPause");
  }

  @override
  onResume() {
    print("ImplementsLifecycleObserver onResume");
  }

  @override
  onDestroy() {
    print("ImplementsLifecycleObserver onDestroy");
  }
}

/// Mixin方式生命周期监听器
class MXLifecycleObserver extends Object with LifecycleObserverMixin {
  @override
  onCreate() {
    print("MXLifecycleObserver onCreate");
  }
}

void main(){
  var lifecycleOwner = TestLifecycleOwner();

  lifecycleOwner.lifecycle.addObserver(ExtendsLifecycleObserver());
  lifecycleOwner.lifecycle.addObserver(ImplementsLifecycleObserver());
  lifecycleOwner.lifecycle.addObserver(MXLifecycleObserver());

  // 直接创建实例的方式生命周期监听器
  lifecycleOwner.lifecycle.addObserver(LifecycleObserver(
          onCreate: () => print("onCreate"),
          onResume: () => print("onResume"),
          onPause:  () => print("onPause"),
          onDestroy:() => print("onDestroy"),);

  // 模拟生命周期
  lifecycleOwner.create();
  lifecycleOwner.resume();
  lifecycleOwner.pause();
  lifecycleOwner.resume();
  lifecycleOwner.pause();
  lifecycleOwner.destroy();
}

```

## ViewModel

``` dart

/// ViewModel实现类，用于提供数据和完成业务逻辑，与ui无直接关联，仅与生命周期相关
class TestViewModel extends ViewModel {
  var count = 0;

  TestViewModel() {
    print("TestViewModel init $count");
  }

  add() {
    print("TestViewModel ${++count}");
  }

  @override
  void onCleared() {
    print("TestViewModel onCleared $count");
  }
}

/// 与[TestViewModel]对应的构建器，由于flutter不允许反射，所以使用构造器模式
class TestViewModelProvider extends ViewModelProvider<TestViewModel> {
  @override
  TestViewModel createViewModel() => TestViewModel();
}

class Test2ViewModel extends ViewModel {
  var count = 0;

  Test2ViewModel() {
    print("Test2ViewModel init $count");
  }

  add() {
    print("Test2ViewModel ${++count}");
  }

  @override
  void onCleared() {
    print("Test2ViewModel onCleared $count");
  }
}

class Test2ViewModelProvider extends ViewModelProvider<Test2ViewModel> {
  @override
  Test2ViewModel createViewModel() => Test2ViewModel();
}

void main(){

  var lifecycleOwner = TestLifecycleOwner();

  lifecycleOwner.lifecycle.addObserver(LifecycleObserver(onCreate: () {
    // 获取viewModel对象，通过对应类型的ViewModelProvider实例
    var viewModel = getViewModel(lifecycleOwner, TestViewModelProvider());
    viewModel.add();
  }, onResume: () {
    // 第二次获取viewModel对象，在这个lifecycleOwner中返回上次创建的对象
    var viewModel = getViewModel(lifecycleOwner, TestViewModelProvider());
    viewModel.add();

    // 获取新的viewModel对象
    var viewModel2 = getViewModel(lifecycleOwner, Test2ViewModelProvider());
    viewModel2.add();
  }));

  lifecycleOwner.create();
  lifecycleOwner.resume();
  lifecycleOwner.pause();
  lifecycleOwner.destroy();

  var lifecycleOwner2 = TestLifecycleOwner();

  lifecycleOwner2.lifecycle.addObserver(LifecycleObserver(onCreate: () {
    // 在新的lifecycleOwner2中获取的viewModel为一个新对象
    var viewModel = getViewModel(lifecycleOwner2, TestViewModelProvider());
    viewModel.add();
  }, onResume: () {
    var viewModel = getViewModel(lifecycleOwner2, TestViewModelProvider());
    viewModel.add();
  }));

  lifecycleOwner2.create();
  lifecycleOwner2.resume();
  lifecycleOwner2.pause();
  lifecycleOwner2.destroy();
}

```

## LiveData

``` dart

void main(){

  var liveData = MutableLiveData<int>();

  var lifecycleOwner = TestLifecycleOwner();

  lifecycleOwner.lifecycle.addObserver(LifecycleObserver(onCreate: () {
    liveData.of(lifecycleOwner).listen((value) {
      print("liveData new value:$value");
    });
  }, onResume: () {
    print("onResume");
  }));

  lifecycleOwner.create();

  // 由于liveData基于[Stream]实现，所以这个测试只能打印一次值2
  liveData.value = 2;
  lifecycleOwner.resume();
  liveData.value = 3;
  liveData.value = 4;
  lifecycleOwner.pause();
  liveData.value = 5;
  lifecycleOwner.destroy();
  liveData.value = 6;
}

```

## ChangeObservable

``` dart

  // 该方法的签名与flutter中[State.setState]一致
  var setState = (VoidCallback) {
    print("change");
  };

  var changeObservable = ChangeObservable();

  // 直接传入[setState]方法，简化代码量
  changeObservable.of(lifecycleOwner).listen(setState);

  // 通知变化
  changeObservable.notify();

```
