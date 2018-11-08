// Created by 超悟空 on 2018/9/18.
// Version 1.0 2018/9/18
// Since 1.0 2018/9/18

import 'package:flutter/material.dart';
import 'package:lifecycle/test_view_model.dart';
import 'package:lifecycle_flutter/lifecycle_flutter.dart';

class TestWidget extends StatefulWidget {
  @override
  State createState() => TestState();
}

class TestState extends State<TestWidget> with StateWithLifeCycleMixin {
  TestViewModel _localViewModel;

  TestViewModel _rootViewModel;

  TestState() {
    _localViewModel = getLocalViewModel(TestViewModelProvider());
  }

  @override
  void initState() {
    super.initState();

    _rootViewModel = getRootViewModel(TestViewModelProvider());

    print("TestState $_rootViewModel");

    _localViewModel.counter.of(this).listen((_) => setState(() => {}));

    _rootViewModel.counter.of(this).listen((_) => setState(() => {}));
  }

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'local:${_localViewModel.counter.value}',
            style: Theme.of(context).textTheme.body2,
          ),
          Text(
            'root:${_rootViewModel.counter.value}',
            style: Theme.of(context).textTheme.body2,
          ),
          RaisedButton(
              child: Text('local Widget add'), onPressed: _localViewModel.add),
          RaisedButton(
              child: Text('root Widget add'), onPressed: _rootViewModel.add),
        ],
      );
}
