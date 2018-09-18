// Created by 超悟空 on 2018/9/18.
// Version 1.0 2018/9/18
// Since 1.0 2018/9/18

import 'package:lifecycle_flutter/lifecycle_flutter.dart';

class TestViewModelProvider implements ViewModelProvider<TestViewModel> {
  @override
  TestViewModel createViewModel() => TestViewModel();
}

class TestViewModel extends ViewModel {
  final _counter = MutableLiveData<int>()..value = 0;

  LiveData<int> get counter => _counter;

  void add() => _counter.value++;
}
