import 'dart:convert';
import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      final dir = Directory('../../docs/evidence/redesign/perf');
      await dir.create(recursive: true);
      final summaries = <String, dynamic>{};
      for (final key in ['home_scroll', 'tab_switch', 'attendance_scroll']) {
        final timeline = driver.Timeline.fromJson(
          data![key] as Map<String, dynamic>,
        );
        final summary = driver.TimelineSummary.summarize(timeline);
        await summary.writeTimelineToFile(
          key,
          pretty: true,
          includeSummary: true,
          destinationDirectory: dir.path,
        );
        summaries[key] = {
          'average_frame_build_time_millis': summary
              .computeAverageFrameBuildTimeMillis(),
          '90th_percentile_frame_build_time_millis': summary
              .computePercentileFrameBuildTimeMillis(90),
          '99th_percentile_frame_build_time_millis': summary
              .computePercentileFrameBuildTimeMillis(99),
          'worst_frame_build_time_millis': summary
              .computeWorstFrameBuildTimeMillis(),
          'missed_frame_build_budget_count': summary
              .computeMissedFrameBuildBudgetCount(),
          'average_frame_rasterizer_time_millis': summary
              .computeAverageFrameRasterizerTimeMillis(),
          '90th_percentile_frame_rasterizer_time_millis': summary
              .computePercentileFrameRasterizerTimeMillis(90),
          '99th_percentile_frame_rasterizer_time_millis': summary
              .computePercentileFrameRasterizerTimeMillis(99),
          'missed_frame_rasterizer_budget_count': summary
              .computeMissedFrameRasterizerBudgetCount(),
          'frame_count': summary.countFrames(),
        };
      }
      await File(
        '${dir.path}/summary.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(summaries));
    },
  );
}
