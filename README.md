BMI_TRACKER
一款基于 Flutter 的体重/身高记录与 BMI 趋势分析 Mini App（离线可用）。
功能简介
概览页：展示最近一次测量（日期/体重/BMI/状态）、目标体重进度、近 7 日统计
记录页：新增测量记录（日期/体重/身高），历史列表展示（支持同日多次测量）
趋势页：折线图展示体重趋势，并同时展示身高趋势（同日去重，固定 Y 轴范围）
技术点
Flutter UI：BottomNavigationBar 多页面
本地存储：
SQLite（sqflite）保存测量记录
SharedPreferences 保存目标体重
数据处理：
同日多次测量排序：date DESC, id DESC
趋势按日去重：保留当日最后一次记录
运行环境
Flutter 3.38.5（stable）
Android Studio + Android Emulator
如何运行
flutter pub get
flutter run
