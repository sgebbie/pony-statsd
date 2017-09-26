/**
 * Pony StatsD Library
 * Copyright (c) 2017 - Stewart Gebbie. Licensed under the MIT licence.
 * vim: set ts=2 sw=0:
 */
use col = "collections"

/*
See: https://github.com/etsy/statsd/blob/master/docs/metric_types.md

Simply group into batches that fit in a given UDP packet and separate with \n

Within a batch local aggregation can be performed up to a given resolution.
*/

// TODO make each bucket key Hashable and Equatable

interface Bucket
	fun bucket(): String
	fun val flush(completion: {()} val = {() => None} val)

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
	fun val flush(completion: {()} val = {() => None} val) => _statsd._flush(this, completion)

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
	fun val flush(completion: {()} val = {() => None} val) => _statsd._flush(this, completion)

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
	fun val flush(completion: {()} val = {() => None} val) => _statsd._flush(this, completion)

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
	fun val flush(completion: {()} val = {() => None} val) => _statsd._flush(this, completion)

	fun val add(value: I64) =>
		_statsd._post_set_add(this, value)

type Metric is (Counter | Gauge | Timer | Set)

primitive CounterAdd
	fun opcode(): String => "c"
primitive GaugeSet
	fun opcode(): String => "g"
primitive GaugeInc
	fun opcode(): String => "g"
	fun opprefix(): U8 => '+'
	fun opprefix_inverse(): U8 => '-'
primitive GaugeDec
	fun opcode(): String => "g"
	fun opprefix(): U8 => '-'
	fun opprefix_inverse(): U8 => '+'
primitive TimerRecord
	fun opcode(): String => "ms"
primitive SetInclude
	fun opcode(): String => "s"

type MetricOp is (CounterAdd | GaugeSet | GaugeInc | GaugeDec | TimerRecord | SetInclude)

type Measurement is (String, MetricOp, I64, F32)

primitive StatsDFormat
	""" Format measurements according the statsd line protocol. """

	fun apply(bucket: String, op: MetricOp, value: I64, sample_ratio: F32 = 0.0): String =>
		// we use matching and precalculate the length to improve performance
		match (bucket, op, value, sample_ratio)
		// gauges
		| (let b: String, let o: (GaugeSet) , let v: I64, _) if v >= 0 =>
			recover val
				let vs: String = v.string()
				let m: String ref = recover String(b.size() + vs.size() + 3) end
				// let space: USize = m.space() // for debugging - test reservation
				m.>append(b).>push(':').>append(vs).>push('|').>append(o.opcode())
				// if m.space() != space then return "~" end ; m
			end
		| (let b: String, let o: (GaugeSet) , let v: I64, _) if v < 0 =>
			recover val
				let vs: String = v.string()
				let m: String ref = recover String((2 * b.size()) + vs.size() + 8) end
				// let space: USize = m.space() // for debugging - test reservation
				m.>append(b).>append(":0|g\n")
				m.>append(b).>push(':').>append(vs).>push('|').>append(o.opcode())
				// if m.space() != space then return "~" end ; m
			end

		| (let b: String, let o: (GaugeInc | GaugeDec) , let v: I64, _) if v >= 0 =>
			recover val
				let vs: String = v.string()
				let m: String ref = recover String(b.size() + vs.size() + 4) end
				// let space: USize = m.space() // for debugging - test reservation
				m.>append(b).>push(':')
					.>push(o.opprefix()).>append(vs)
					.>push('|').>append(o.opcode())
				// if m.space() != space then return "~" end ; m
			end
		| (let b: String, let o: (GaugeInc | GaugeDec) , let v: I64, _) if v < 0 =>
			recover val
				let vs: String = (-v).string()
				let m: String ref = recover String(b.size() + vs.size() + 4) end
				// let space: USize = m.space() // for debugging - test reservation
				m.>append(b).>push(':')
					.>push(o.opprefix_inverse()).>append(vs)
					.>push('|').>append(o.opcode())
				// if m.space() != space then return "~" end ; m
			end

		// timers and counters
		| (let b: String, let o: (CounterAdd | TimerRecord) , let v: I64, let s: F32) if s == 0.0 =>
			recover val
				let vs: String = v.string()
				let os: String = o.opcode()
				let m: String ref = recover String(b.size() + vs.size() + os.size() + 2) end
				// let space: USize = m.space() // for debugging - test reservation
				m.>append(b).>push(':').>append(vs).>push('|').>append(os)
				// if m.space() != space then return "~" end ; m
			end
		| (let b: String, let o: (CounterAdd | TimerRecord) , let v: I64, let s: F32) if s != 0.0 =>
			recover val
				let vs: String = v.string()
				let ss: String = s.string()
				let os: String = o.opcode()
				let m: String ref = recover String(b.size() + vs.size() + os.size() + ss.size() + 4) end
				// let space: USize = m.space() // for debugging - test reservation
				m.>append(b).>push(':').>append(vs).>push('|').>append(os)
					.>append("|@").>append(ss)
				// if m.space() != space then return "~" end ; m
			end

		// sets
		| (let b: String, let o: (SetInclude) , let v: I64, _) =>
			recover val
				let vs: String = v.string()
				let m: String ref = recover String(b.size() + vs.size() + 3) end
				// let space: USize = m.space() // for debugging - test reservation
				m.>append(b).>push(':').>append(vs).>push('|').>append(op.opcode())
				// if m.space() != space then return "~" end ; m
			end
		else
			"unformattable." + bucket + ":1|c"
		end
