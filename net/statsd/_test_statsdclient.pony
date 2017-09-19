use "ponytest"

actor StatsDClientTests is TestList

	new create(env: Env) =>
		PonyTest(env, this)

	new make() =>
		None

	fun tag tests(test: PonyTest) =>
		test(_TestMetricCreation)
		test(_TestMetricAccumulate)

class iso _TestMetricCreation is UnitTest
	"""Creates a client that allocates metrics."""

	fun name(): String => "statsd:metric-creation"

	fun apply(h: TestHelper) =>
		h.long_test(1_000_000_000)
		let statsd: StatsD = StatsD
		let client: StatsDClient = StatsDClient(statsd)
		client.doStuff({() => h.complete(true) } val)

class iso _TestMetricAccumulate is UnitTest
	"""Creates a client that checks accumulated metrics."""

	fun name(): String => "statsd:metric-accumulation"

	fun apply(h: TestHelper) =>
		h.long_test(1_000_000_000)
		let acc: StatsDTransportArray = StatsDTransportArray
		let statsd: StatsD = StatsD(StatsDAccumulator(where transport = acc))
		let client: StatsDClient = StatsDClient(statsd)
		client.doStuff({()(h) =>
			// depends on 'doStuff' calling flushcw
			// (but we might still get a timing issue between updates and flush)
			acc.snapshot({(lines: Array[String] iso)(h) =>
				let ll: Array[String] ref = consume lines
				for l in ll.values() do
					h.env.out.print(l)
				end
				h.complete(true)
			} val)
		} val)

actor StatsDClient

	let _statsd: StatsD
	let count: Counter val
	let gauge: Gauge val
	let timer: Timer val
	let set: Set val

	new create(statsd: StatsD val) =>
		_statsd = statsd
		count = statsd.counter(where bucket="my.counter", initial_value=0, sample_ratio=1.0)
		gauge = statsd.gauge(where bucket="my.gauge", initial_value=0)
		timer = statsd.timer(where bucket="my.timer", time_unit=MILLISECONDS, sample_ratio=1.0)
		set = statsd.set(where bucket="my.set")

	be doStuff(completion: {()} val = {() => None} val) =>
		count.now(513)
		gauge.>inc(5).>dec(7).>set(500)
		timer.>was(10,SECONDS).>ms(10).>nanos(1000).>micros(100).>sec(50).>min(10).>hr(5).>day(1)
		set.>add(5).>add(52)
		_statsd.flush(completion)
