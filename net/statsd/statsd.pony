"""StatsD telemetry collection."""
use col = "collections"

/* See: https://github.com/etsy/statsd/blob/master/docs/metric_types.md */

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
