"""StatsD telemetry collection."""

use col = "collections"

/*

See: https://github.com/etsy/statsd/blob/master/docs/metric_types.md

Simply group into batches that fit in a given UDP packet and separate with \n

Within a batch local aggregation can be performed up to a given resolution.
 */

// TODO make each bucket key Hashable and Equatable

interface Bucket
	fun bucket(): String
	fun val flush()

class val Counter
"""
Count -
  "%s:%d|c" (bucket, value) or
  "%s:%d|c|@%f" (bucket, value, sample-ratio)
"""

	let _statsd: StatsDAccumulator
	let _bucket: String
	let _samples: F32

	new iso create(statsd: StatsDAccumulator, stats_bucket: String, sample_ratio: F32 = 0.0) =>
		_statsd = statsd
		_bucket = stats_bucket
		_samples = sample_ratio

	fun bucket(): String => _bucket
	fun val flush() => _statsd._flush(this)

	fun val now(value: I64) =>
		_statsd._post_counter_add(this, value)

class val Timer
"""
Duration -
	"%s:%d|ms" (bucket, value) or
  "%s:%d|ms|@%f" (bucket, value, sample-ratio)
"""

	let _statsd: StatsDAccumulator
	let _bucket: String
	let _samples: F32
	let _time_unit: TimeUnit

	new iso create(statsd: StatsDAccumulator, stats_bucket: String, time_unit: TimeUnit = MILLISECONDS, sample_ratio: F32 = 0.0) =>
		_statsd = statsd
		_bucket = stats_bucket
		_samples = sample_ratio
		_time_unit = time_unit

	fun bucket(): String => _bucket
	fun val flush() => _statsd._flush(this)

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

	let _statsd: StatsDAccumulator
	let _bucket: String

	new iso create(statsd: StatsDAccumulator, stats_bucket: String) =>
		_statsd = statsd
		_bucket = stats_bucket

	fun bucket(): String => _bucket
	fun val flush() => _statsd._flush(this)

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

	let _statsd: StatsDAccumulator
	let _bucket: String

	new val create(statsd: StatsDAccumulator, stats_bucket: String) =>
		_statsd = statsd
		_bucket = stats_bucket

	fun bucket(): String => _bucket
	fun val flush() => _statsd._flush(this)

	fun val add(value: I64) =>
		_statsd._post_set_add(this, value)

type Metric is (Counter | Gauge | Timer | Set)

primitive CounterAdd
	fun opcode(): String => "c"
	fun opprefix(): String => "c"
primitive GaugeSet
	fun opcode(): String => "g"
	fun opprefix(): String => ""
primitive GaugeInc
	fun opcode(): String => "g"
	fun opprefix(): String => "+"
primitive GaugeDec
	fun opcode(): String => "g"
	fun opprefix(): String => "-"
primitive TimerRecord
	fun opcode(): String => "ms"
	fun opprefix(): String => ""
primitive SetInclude
	fun opcode(): String => "s"
	fun opprefix(): String => ""

type MetricOp is (CounterAdd | GaugeSet | GaugeInc | GaugeDec | TimerRecord | SetInclude)

type Measurement is (String, MetricOp, I64, F32)

interface tag StatsDTransport
	""" An emitter of metrics. """

	be emit(bucket: String, op: MetricOp, value: I64, sample_ratio: F32 = 0.0) =>
		""" Buffer a measurement for transport.

				It might be sent if the buffer is full.
		"""
		None

	be emit_batch(batch: Array[Measurement] val) =>
		""" Buffer all measurements for transport.

				It might force a flush of earlier measurements first in order
				to fit all of these measurements into one frame.
		"""
		// used to group gauge set=0 & set = negative into one frame
		None

	be flush() =>
		""" Force the sending of all buffered measurements. """
		None

actor StatsDTransportNop is StatsDTransport


actor StatsDAccumulator
	""" An accumlator and aggregator of metrics metrics. """

	let _flush_millis: U32 // time between flushing accumulated metrics to the transport layer
	let _transport: StatsDTransport // gateway to transport data out to external tooling

	let _gauges: col.Map[String,(Bool, I64)] // track the sum of 'inc/dec' and if 'set' was used (note, if negative after 'set' then we need to emit a "set to zero" before sending the decrement. But care must be taken to ensure that this is in the same packet so that we accidentally processs the set=0 after the decrement.
	let _counters: col.Map[String,I64] // simply track the sum
	let _timers: col.Map[String,Array[I64]] // track all the values to be averaged
	let _sets: col.Map[String,col.Set[String]] // track all the values

	new create(flush_millis: U32 = 500, transport: StatsDTransport = StatsDTransportNop) =>
		_flush_millis = flush_millis
		_transport = transport

		_gauges = col.Map[String,(Bool,I64)]()
		_counters = col.Map[String,I64]()
		_timers = col.Map[String,Array[I64]]()
		_sets = col.Map[String,col.Set[String]]()

	// -- common

	be _flush(metric: Metric) =>
		None

	// -- counters

	be _post_counter_add(metric: Counter, value: I64) =>
		None

	// -- gauges

	be _post_gauge_inc(metric: Gauge, value: I64) =>
		None

	be _post_gauge_dec(metric: Gauge, value: I64) =>
		None

	be _post_gauge_set(metric: Gauge, value: I64) =>
		None

	// -- sets

	be _post_set_add(metric: Set, value: I64) =>
		None

	// -- timers

	be _post_timer_log(metric: Timer, value: I64, unit: TimeUnit) =>
		None

class val StatsD
	""" A factor for metrics. """

	let _statsd: StatsDAccumulator

	new val create(statsd: StatsDAccumulator = StatsDAccumulator) =>
		_statsd = statsd

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
