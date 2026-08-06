/// Modules on the Chronos Home command center.
enum HomeModule {
  timeCore,
  dayProgress,
  nextAlarm,
  focusStatus,
  chronosFeed,
  worldPeek,
  timeJourney,
  energy,
  statsPeek,
}

extension HomeModuleX on HomeModule {
  String get title {
    switch (this) {
      case HomeModule.timeCore:
        return 'TIME CORE';
      case HomeModule.dayProgress:
        return 'DAY PROGRESS';
      case HomeModule.nextAlarm:
        return 'NEXT ALARM';
      case HomeModule.focusStatus:
        return 'FOCUS';
      case HomeModule.chronosFeed:
        return 'EVENTS';
      case HomeModule.worldPeek:
        return 'WORLD';
      case HomeModule.timeJourney:
        return 'JOURNEY';
      case HomeModule.energy:
        return 'ENERGY';
      case HomeModule.statsPeek:
        return 'STATS';
    }
  }

  static HomeModule fromName(String n) {
    return HomeModule.values.firstWhere(
      (e) => e.name == n,
      orElse: () => HomeModule.timeCore,
    );
  }
}

const kDefaultHomeModules = <HomeModule>[
  HomeModule.timeCore,
  HomeModule.energy,
  HomeModule.dayProgress,
  HomeModule.nextAlarm,
  HomeModule.focusStatus,
  HomeModule.chronosFeed,
  HomeModule.timeJourney,
  HomeModule.statsPeek,
];
