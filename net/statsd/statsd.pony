"""StatsD telemetry collection."""

use col = "collections"

/*

See: https://github.com/etsy/statsd/blob/master/docs/metric_types.md

Simply group into batches that fit in a given UDP packet and separate with \n

Within a batch local aggregation can be performed up to a given resolution.
 */

// TODO make each bucket key Hashable and Equatable

class val Counter
"""
Count -
  "%s:%d|c" (bucket, value) or
  "%s:%d|c|@%f" (bucket, value, sample-ratio)
"""

	let _statsd: StatsD
	let _bucket: String
	let _samples: F32

	new iso create(statsd: StatsD, bucket: String, sample_ratio: F32 = 0.0) =>
		_statsd = statsd
		_bucket = bucket
		_samples = sample_ratio

	fun val now(value: I64) =>
		None

class val Timer
"""
Duration -
	"%s:%d|ms" (bucket, value) or
  "%s:%d|ms|@%f" (bucket, value, sample-ratio)
"""

	let _statsd: StatsD
	let _bucket: String
	let _samples: F32
	let _time_unit: TimeUnit

	new iso create(statsd: StatsD, bucket: String, time_unit: TimeUnit = MILLISECONDS, sample_ratio: F32 = 0.0) =>
		_statsd = statsd
		_bucket = bucket
		_samples = sample_ratio
		_time_unit = time_unit

	fun val was(value: I64, unit: TimeUnit) =>
		// convert to the the configured time unit
		_statsd._post_timer_log(this, _time_unit.convert(value, unit), _time_unit)

	fun val nanos(value: I64) => was(value, NANOSECONDS)
	fun val micros(value: I64) => was(value, MICROSECONDS)
	fun val ms(value: I64) => was(value, MILLISECONDS)
	fun val sec(value: I64) => was(value, SECONDS)
	fun val min(value: I64) => was(value, MINUTES)
	fun val hr(value: I64) => was(value, HOURS)
	fun val day(value: I64) => was(value, DAYS)

class val Gauge
"""
Gauge -
  "%s:%d|g" (bucket, value) or
  "%s:+%d|g" (bucket, inc) or
  "%s:-%d|g" (bucket, dec)
"""

	let _statsd: StatsD
	let _bucket: String

	new iso create(statsd: StatsD, bucket: String) =>
		_statsd = statsd
		_bucket = bucket

	fun val inc(value: I64) =>
		_statsd._post_gauge_inc(this, value)

	fun val dec(value: I64) =>
		_statsd._post_gauge_dec(this, value)

	fun val set(value: I64) =>
		_statsd._post_gauge_set(this, value)

class val Set
"""
Set -
  "%s:%d|s" (bucket, value)
"""

	let _statsd: StatsD
	let _bucket: String

	new val create(statsd: StatsD, bucket: String) =>
		_statsd = statsd
		_bucket = bucket

	fun val add(value: I64) =>
		_statsd._post_set_add(this, value)

type Metric is (Counter | Gauge | Timer | Set)

actor StatsD

	let _gauges: col.Map[String,(Bool, I64)] // track the sum of 'inc/dec' and if 'set' was used
	let _counters: col.Map[String,I64] // simply track the sum
	let _timers: col.Map[String,Array[I64]] // track all the values to be averaged
	let _sets: col.Map[String,String] // track all the values

	new create() =>
		_gauges = col.Map[String,(Bool,I64)]()
		_counters = col.Map[String,I64]()
		_timers = col.Map[String,Array[I64]]()
		_sets = col.Map[String,String]()

	fun val counter(bucket: String,
			initial_value: I64 = 0, sample_ratio: F32 = 0.0): Counter val^ =>
		(recover val Counter(this, bucket, sample_ratio) end)
			.>now(initial_value)

	fun val timer(bucket: String,
			initial_value: I64 = 0, time_unit: TimeUnit = MILLISECONDS,
			sample_ratio: F32 = 0.0): Timer val^ =>
 		(recover val Timer(this, bucket, time_unit, sample_ratio) end)
			.>was(initial_value, time_unit)

 	fun val gauge(bucket: String,
			initial_value: I64): Gauge val^ =>
 		(recover val Gauge(this, bucket) end)
			.>set(initial_value)

 	fun val set(bucket: String): Set val^ =>
 		recover val Set(this, bucket) end

	be _post_counter_add(metric: Counter, value: I64) =>
		None

	be _post_gauge_inc(metric: Gauge, value: I64) =>
		None

	be _post_gauge_dec(metric: Gauge, value: I64) =>
		None

	be _post_gauge_set(metric: Gauge, value: I64) =>
		None

	be _post_set_add(metric: Set, value: I64) =>
		None

	be _post_timer_log(metric: Timer, value: I64, unit: TimeUnit) =>
		None
