/// Wall clock used by attendance and UI. Tests replace it to keep time-based
/// behavior deterministic; production uses the device clock.
DateTime Function() appClock = DateTime.now;
