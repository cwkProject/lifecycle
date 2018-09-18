# lifecycle_flutter

模仿Android Lifecycle组件功能的Flutter生命周期实现

## Usage
* 添加 `lifecycle_flutter` 到 [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).
* import 'package:lifecycle_flutter/lifecycle_flutter.dart';

实现State时通过继承或混入StateWithLifeCycle来获取生命周期管理能力和ViewModel管理能力。
在实现了StateWithLifeCycle的State中通过 getLocalViewModel来获取与自身生命周期绑定的ViewModel实例。
通过getRootViewModel获取最顶层根StateWithLifeCycle管理的ViewModel。

在ViewModel中可以管理数据和执行业务相关操作，与UI组件解耦同时具有UI State的生命周期感知。

通过LifecycleObserver可以实现具有生命周期感知的功能组件。

通过LiveData可以监听数据的变化。

有关更多Lifecycle ViewModel LiveData的使用请查看 [lifecycle_core](https://github.com/cwkProject/lifecycle/blob/master/lifecycle_core/README.md)

## 生命周期注入

``` dart

/// 使用生命周期注入
///
/// 需要继承或混入[StateWithLifeCycle]，
/// [StateWithLifeCycle]实现了[LifecycleOwner]和[ViewModelStoreOwner]，
/// 此时[State]具有提供生命周期事件和管理[ViewModel]的能力。
class TestState extends State<TestWidget> with StateWithLifeCycle {
  
  /// 本[State]管理的ViewModel
  TestViewModel _localViewModel;

  /// 根[State]管理的ViewModel
  TestViewModel _rootViewModel;

  TestState() {
    // 获取本地ViewModel
    _localViewModel = getLocalViewModel(TestViewModelProvider());
  }

  @override
  void initState() {
    super.initState();

    // 获取根ViewModel，建议在[initState]中获取，不能在构造函数中获取，因为需要使用[BuildContext]对象
    _rootViewModel = getRootViewModel(TestViewModelProvider());

    // 监听本地counter值的变化
    _localViewModel.counter.of(this).listen((_) => setState(() => {}));

    // 监听根counter值的变化
    _rootViewModel.counter.of(this).listen((_) => setState(() => {}));
  }

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'local:${_localViewModel.counter.value}',//绑定本地值
            style: Theme.of(context).textTheme.body2,
          ),
          Text(
            'root:${_rootViewModel.counter.value}',//绑定根值
            style: Theme.of(context).textTheme.body2,
          ),
          RaisedButton(
              child: Text('local Widget add'), onPressed: _localViewModel.add),// 增加本地值
          RaisedButton(
              child: Text('root Widget add'), onPressed: _rootViewModel.add),// 增加根值
        ],
      );
}

/// 上述代码使用的[TestViewModel]提供者
class TestViewModelProvider implements ViewModelProvider<TestViewModel> {
  @override
  TestViewModel createViewModel() => TestViewModel();
}

/// 上述代码使用的[TestViewModel]实现
class TestViewModel extends ViewModel {
  /// [LiveData]对象实例，具有生命周期监听能力
  final _counter = MutableLiveData<int>()..value = 0;

  LiveData<int> get counter => _counter;

  void add() => _counter.value++;
}

```

## 根State实现

``` dart

/// 这是官方默认项目示例的改造，也是上面Widget的父Widget
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

/// 必须继承或混入[StateWithLifeCycle]来获得生命周期管理能力
///
/// 多个子级[StateWithLifeCycle]只能获取最顶级的[StateWithLifeCycle]实现对象，
/// 基于[BuildContext.rootAncestorStateOfType]实现。
/// 多个[StateWithLifeCycle]需要共享一个[ViewModel]对象时请实现一个公共的父[StateWithLifeCycle]。
class _MyHomePageState extends State<MyHomePage> with StateWithLifeCycle {
  TestViewModel _localViewModel;

  _MyHomePageState() {
    // 父State可以直接获取loacl[ViewModel]，与上面代码的[_rootViewModel]是同一个对象
    _localViewModel = getLocalViewModel(TestViewModelProvider());

    // 子Widget改变[_rootViewModel.counter]可以被监听到
    _localViewModel.counter.of(this).listen((_) => setState(() => {}));
  }

  @override
  Widget build(BuildContext context) {
 
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Center(
        child: new Column(
          
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              'You have pushed the button this many times:',
            ),
            new Text(
              '${_localViewModel.counter.value}', 
              style: Theme.of(context).textTheme.display1,
            ),
            TestWidget(),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _localViewModel.add, // 子Widget也可以监听到变化
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ),
    );
  }
}

```


