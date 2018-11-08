import 'package:lifecycle_core/lifecycle_core.dart';

void main() {
  testLiveData();

//  testViewModel();
//  testLifecycle();
}

void testLifecycle() {
  var lifecycleOwner = TestLifecycleOwner();

  lifecycleOwner.lifecycle
      .addObserver(LifecycleObserver(onCreate: () => print("1 onCreate")));

  lifecycleOwner.lifecycle.addObserver(ExtendsLifecycleObserver());
  lifecycleOwner.lifecycle.addObserver(ImplementsLifecycleObserver());
  lifecycleOwner.lifecycle.addObserver(MXLifecycleObserver());

  lifecycleOwner.lifecycle.addObserver(LifecycleObserver(onCreate: () {
    print("2 onCreate");

    lifecycleOwner.lifecycle.addObserver(LifecycleObserver(
        onCreate: () => print("3 onCreate"),
        onResume: () {
          print("3 onResume begin");
          lifecycleOwner.lifecycle.addObserver(LifecycleObserver(
            onCreate: () => print("4 onCreate"),
            onResume: () => print("4 onResume"),
            onPause: () {
              print("4 onPause begin");

              var observer = LifecycleObserver(
                  onCreate: () => print("5 onCreate"),
                  onResume: () => print("5 onResume"),
                  onPause: () => print("5 onPause"));

              lifecycleOwner.lifecycle.addObserver(observer);

              lifecycleOwner.lifecycle
                  .addObserver(LifecycleObserver(onCreate: () {
                print("6 onCreate");
                var observer =
                    LifecycleObserver(onCreate: () => print("7 onCreate"));

                lifecycleOwner.lifecycle.addObserver(observer);
                lifecycleOwner.lifecycle.removeObserver(observer);
              }, onResume: () {
                print("6 onResume");
                lifecycleOwner.lifecycle.removeObserver(observer);
              }, onPause: () {
                lifecycleOwner.lifecycle.addObserver(observer);
                lifecycleOwner.lifecycle.removeObserver(observer);
                lifecycleOwner.lifecycle.addObserver(observer);
              }));

              print("4 onPause end");
            },
            onDestroy: () => print("4 onDestroy"),
          ));

          print("3 onResume end");
        },
        onDestroy: () {
          print("3 onDestroy");
          lifecycleOwner.lifecycle.addObserver(LifecycleObserver(
              onCreate: () => print("3 onDestroy onCreate"),
              onDestroy: () => print("3 onDestroy onDestroy")));
        }));
  }));

  lifecycleOwner.create();
  lifecycleOwner.resume();
  var addObserver = LifecycleObserver(
      onCreate: () => print("add onCreate"),
      onResume: () => print("add onResume"),
      onPause: () => print("add onPause"));
  lifecycleOwner.lifecycle.addObserver(addObserver);
  lifecycleOwner.pause();
  lifecycleOwner.resume();
  lifecycleOwner.lifecycle.removeObserver(addObserver);
  lifecycleOwner.resume();
  lifecycleOwner.pause();
  lifecycleOwner.destroy();
}

void testViewModel() {
  var lifecycleOwner = TestMXLifecycleOwner();

  lifecycleOwner.lifecycle.addObserver(LifecycleObserver(onCreate: () {
    var viewModel = getViewModel(lifecycleOwner, TestViewModelProvider());
    viewModel.add();
  }, onResume: () {
    var viewModel = getViewModel(lifecycleOwner, TestViewModelProvider());
    viewModel.add();

    var viewModel2 = getViewModel(lifecycleOwner, Test2ViewModelProvider());
    viewModel2.add();
  }, onPause: () {
    var viewModel = getViewModel(lifecycleOwner, TestViewModelProvider());
    viewModel.add();

    var viewModel2 = getViewModel(lifecycleOwner, Test2ViewModelProvider());
    viewModel2.add();
  }, onDestroy: () {
    var viewModel2 = getViewModel(lifecycleOwner, Test2ViewModelProvider());

    var viewModel = getViewModel(lifecycleOwner, TestViewModelProvider());
    print("onDestroy $viewModel ; $viewModel2");
    viewModel.add();
    viewModel2.add();
  }));

  lifecycleOwner.create();
  lifecycleOwner.resume();
  lifecycleOwner.pause();
  lifecycleOwner.destroy();

  var lifecycleOwner2 = TestMXLifecycleOwner();

  lifecycleOwner2.lifecycle.addObserver(LifecycleObserver(onCreate: () {
    var viewModel = getViewModel(lifecycleOwner2, TestViewModelProvider());
    viewModel.add();
  }, onResume: () {
    var viewModel = getViewModel(lifecycleOwner2, TestViewModelProvider());
    viewModel.add();

    var viewModel2 = getViewModel(lifecycleOwner2, Test2ViewModelProvider());
    viewModel2.add();
  }, onPause: () {
    var viewModel = getViewModel(lifecycleOwner2, TestViewModelProvider());
    viewModel.add();

    var viewModel2 = getViewModel(lifecycleOwner2, Test2ViewModelProvider());
    viewModel2.add();
  }, onDestroy: () {
    var viewModel2 = getViewModel(lifecycleOwner2, Test2ViewModelProvider());

    var viewModel = getViewModel(lifecycleOwner2, TestViewModelProvider());
    print("onDestroy $viewModel ; $viewModel2");
    viewModel.add();
    viewModel2.add();
  }));

  lifecycleOwner2.create();
  lifecycleOwner2.resume();
  lifecycleOwner2.pause();
  lifecycleOwner2.destroy();
}

void testLiveData() {
  var liveData = MutableLiveData<int>();

  var lifecycleOwner = TestMXLifecycleOwner();

  var stream = liveData.of(lifecycleOwner);

  liveData.value = 1;

  lifecycleOwner.lifecycle.addObserver(LifecycleObserver(onCreate: () {
    liveData.of(lifecycleOwner).listen((value) {
      print("liveData new value:$value");
    });
  }, onResume: () {
    print("onResume");
  }, onPause: () {
    print("onPause");
    stream.listen((value) {
      print("stream new value:$value");
    });
  }, onDestroy: () {
    print("onDestroy");
  }));

  var setState = (VoidCallback) {
    print("change");
  };

  var changeObservable = ChangeObservable();

  changeObservable.of(lifecycleOwner).listen(setState);

  changeObservable.notify();

  lifecycleOwner.create();
  lifecycleOwner.resume();
  liveData.value = 2;
  liveData.value = 3;
  liveData.value = 4;
  lifecycleOwner.pause();
  liveData.value = 5;
  lifecycleOwner.destroy();
  liveData.value = 6;
}

class TestLifecycleOwner implements LifecycleOwner, ViewModelStoreOwner {
  final _lifecycleRegistry = LifecycleRegistry();

  final _viewModelStore = ViewModelStore();

  @override
  Lifecycle get lifecycle => _lifecycleRegistry;

  @override
  ViewModelStore get viewModelStore => _viewModelStore;

  create() {
    print("TestLifecycleOwner create");
    _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.onCreate);
  }

  resume() {
    print("TestLifecycleOwner resume");
    _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.onResume);
  }

  pause() {
    print("TestLifecycleOwner pause");
    _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.onPause);
  }

  destroy() {
    print("TestLifecycleOwner destroy");
    _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.onDestroy);
    _viewModelStore.clear();
  }
}

class TestMXLifecycleOwner extends Object with TestLifecycleOwner {}

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

class MXLifecycleObserver extends Object with LifecycleObserverMixin {
  @override
  onCreate() {
    print("MXLifecycleObserver onCreate");
  }
}

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
