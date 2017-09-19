"""StatsD telemetry collection."""
use col = "collections"

/* See: https://github.com/etsy/statsd/blob/master/docs/metric_types.md */

class val StatsD
	""" A factor for metrics. """

	let _statsd: StatsDAccumulator

	new val create(statsd: StatsDAccumulator = StatsDAccumulator) =>
		_statsd = statsd

	fun val flush(completion: {()} val = {() => None} val) =>
		_statsd._flush(where completion = completion)

	fun val counter(bucket: String,
			initial_value: I64 = 0, sample_ratio: F32 = 0.0): Counter val^ =>
		(recover val Counter(_statsd, bucket, sample_ratio) end)
			.>now(initial_value)

	fun val timer(bucket: String,
			initial_value: I64 = 0, time_unit: TimeUnit = MILLISECONDS,
			sample_ratio: F32 = 0.0): Timer val^ =>
		(recover val Timer(_statsd, bucket, time_unit, sample_ratio) end)
			.>was(initial_value, time_unit)

	fun val gauge(bucket: String,
			initial_value: I64): Gauge val^ =>
		(recover val Gauge(_statsd, bucket) end)
			.>set(initial_value)

	fun val set(bucket: String): Set val^ =>
		recover val Set(_statsd, bucket) end
