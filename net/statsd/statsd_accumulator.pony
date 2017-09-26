/**
 * Pony StatsD Library
 * Copyright (c) 2017 - Stewart Gebbie. Licensed under the MIT licence.
 * vim: set ts=2 sw=0:
 */
use col = "collections"
use time = "time"

class NotifyStatsDAccumulator is time.TimerNotify

	let _acc: StatsDAccumulator

	new iso create(accumulator: StatsDAccumulator) =>
		_acc = accumulator

	fun ref apply(timer: time.Timer, count: U64): Bool =>
		_acc._flush()
		true

  fun ref cancel(timer: time.Timer) => None


actor StatsDAccumulator
	""" An accumlator and aggregator of metrics metrics. """

	let _transport: StatsDTransport // gateway to transport data out to external tooling
	let _flush_millis: U64 // time between flushing accumulated metrics to the transport layer
	let _timerfactory: (time.Timers | None)

	var _closed: Bool

	embed _gauges: col.Map[String,(Bool, I64)] // track the sum of 'inc/dec' and if 'set' was used (note, if negative after 'set' then we need to emit a "set to zero" before sending the decrement. But care must be taken to ensure that this is in the same packet so that we accidentally processs the set=0 after the decrement.
	embed _counters: col.Map[String,I64] // simply track the sum
	embed _timers: col.Map[String,Array[I64]] // track all the values to be averaged
	embed _sets: col.Map[String,col.Set[I64]] // track all the values

	new create(transport: StatsDTransport = StatsDTransportNop, flush_millis: U64 = 500, timers: (time.Timers | None) = None) =>
		_flush_millis = flush_millis
		_transport = transport

		_gauges = col.Map[String,(Bool,I64)]()
		_counters = col.Map[String,I64]()
		_timers = col.Map[String,Array[I64]]()
		_sets = col.Map[String,col.Set[I64]]()

		// set up an auto-flush timer
		// (note, the timer must be explicitly disposed)
		_timerfactory = timers
		match _timerfactory
		| (let timers': time.Timers) =>
			let timer: time.Timer iso = time.Timer(NotifyStatsDAccumulator(this)
											, NANOSECONDS.convert(flush_millis.i64(), MILLISECONDS).u64()
											, NANOSECONDS.convert(flush_millis.i64(), MILLISECONDS).u64())
			timers'(consume timer)
		end
		_closed = false

	be dispose() =>
		_closed = true
		_transport.dispose()
		match _timerfactory
		| (let timers: time.Timers) => timers.dispose()
		end

	// -- common

	be _flush(metric: (Metric | None) = None, completion: {()} val = Completion.nop()) =>
		if _closed then completion(); return end
		// gauges
		for pair in _gauges.pairs() do
			(let bucket: String, let gauge: (Bool, I64)) = pair
			(let gb: Bool, let gv: I64) = gauge
			if gb then
				_transport.emit(bucket, GaugeSet, gv)
			else
				if gv < 0 then
					_transport.emit(bucket, GaugeDec, -gv)
				else
					_transport.emit(bucket, GaugeInc, gv)
				end
			end
		end
		// counters
		for pair in _counters.pairs() do
			(let bucket: String, let counter: I64) = pair
			_transport.emit(bucket, CounterAdd, counter)
		end
		// timers
		for pair in _timers.pairs() do
			(let bucket: String, let times: Array[I64]) = pair
			var total: I64 = 0
			for v in times.values() do
				total = total + v
			end
			_transport.emit(bucket, TimerRecord, total / times.size().i64())
		end
		// sets
		for pair in _sets.pairs() do
			(let bucket: String, let set: col.Set[I64]) = pair
			for v in set.values() do
				_transport.emit(bucket, SetInclude, v)
			end
		end
		_transport.flush(completion)

	// -- counters

	be _post_counter_add(metric: Counter, value: I64) =>
		if _closed then return end
		try
			_counters.upsert(metric.bucket(), value, {
				(old: I64, cur: I64): I64 => old + cur
			})?
		end

	// -- gauges

	be _post_gauge_inc(metric: Gauge, value: I64) =>
		if _closed then return end
		try
			_gauges.upsert(metric.bucket(), (false, value), {
				(old: (Bool, I64), cur: (Bool, I64)): (Bool, I64) =>
					(let os: Bool, let ov: I64) = old
					(let cs: Bool, let cv: I64) = cur
					(os or cs, ov + cv)
			})?
		end

	be _post_gauge_dec(metric: Gauge, value: I64) =>
		if _closed then return end
		try
			_gauges.upsert(metric.bucket(), (false, value), {
				(old: (Bool, I64), cur: (Bool, I64)): (Bool, I64) =>
					(let os: Bool, let ov: I64) = old
					(let cs: Bool, let cv: I64) = cur
					(os or cs, ov - cv)
			})?
		end

	be _post_gauge_set(metric: Gauge, value: I64) =>
		if _closed then return end
		try
			_gauges.insert(metric.bucket(), (true, value))?
		end

	// -- timers

	be _post_timer_log(metric: Timer, value: I64, unit: TimeUnit) =>
		if _closed then return end
		try
			if _timers.contains(metric.bucket()) then
				let s: Array[I64] = _timers.apply(metric.bucket())?
				s.push(value)
			else
				let s: Array[I64] = Array[I64]
				s.push(value)
				_timers.update(metric.bucket(), s)
			end
		end

	// -- sets

	be _post_set_add(metric: Set, value: I64) =>
		if _closed then return end
		try
			if _sets.contains(metric.bucket()) then
				let s: col.Set[I64] = _sets.apply(metric.bucket())?
				s.set(value)
			else
				let s: col.Set[I64] = col.Set[I64]
				s.set(value)
				_sets.update(metric.bucket(), s)
			end
		end

