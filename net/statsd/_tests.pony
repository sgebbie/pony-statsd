/**
 * Pony StatsD Library
 * Copyright (c) 2017 - Stewart Gebbie. Licensed under the MIT licence.
 * vim: set ts=2 sw=0:
 */
use "ponytest"
use time="time"

actor Main is TestList
	new create(env: Env) =>
		try
			if (env.args.size() == 2) and (env.args(1)? == "demo") then
				let demo = StatsDDemo(env)
			else
				PonyTest(env, this)
			end
		else
			env.err.print("Bad command line arguments")
			env.exitcode(1)
		end

	new make() =>
		None

	fun tag tests(test: PonyTest) =>
		StatsDClientTests.make().tests(test)
		StatsDFormatTests.make().tests(test)
		StatsDUDPTests.make().tests(test)
		StatsDTests.make().tests(test)

// -- demo

class StatsDDemoTimer is time.TimerNotify
	let _demo: StatsDDemo
	var _ticks: U64

	new iso create(demo: StatsDDemo) =>
		_demo = demo
		_ticks = 0

	fun ref cancel(timer: time.Timer) => None

	fun ref apply(timer: time.Timer, count: U64): Bool =>
		_ticks = _ticks + count
		_demo.record(_ticks)
		if _ticks < (5*90) then true else _demo.dispose() ; false end

actor StatsDDemo

	let _env: Env
	let statsd: StatsD
	let timers: time.Timers

	let demo_gauge: Gauge
	let demo_timer: Timer
	let demo_set: Set
	let demo_count: Counter

	new create(env: Env) =>
		_env = env
		timers = time.Timers
		(statsd, let run: Bool) = try
			(StatsD(env.root as AmbientAuth)?, true)
		else
			(StatsD.create_acc(), false)
		end

		demo_gauge = statsd.gauge("net.gethos.pony.demo.gauge")
		demo_set = statsd.set("net.gethos.pony.demo.set")
		demo_timer = statsd.timer("net.gethos.pony.demo.timer")
		demo_count = statsd.counter("net.gethos.pony.demo.count")

		if run then run_demo() else dispose() end

	be run_demo() =>
		let timer: time.Timer iso = time.Timer(StatsDDemoTimer(this)
			, NANOSECONDS.toNanos(0).u64()
			, MILLISECONDS.toNanos(200).u64()
		)
		timers(consume timer)

	be record(sec: U64) =>
		_env.out.print("tick " + sec.string())
		demo_gauge.inc(1)
		demo_count.now(5 + (sec % 2).i64())
		demo_timer.ms(180 + (sec % 40).i64())
		demo_set.add((sec % 20).i64())

	be dispose() =>
		statsd.dispose()
		timers.dispose()
