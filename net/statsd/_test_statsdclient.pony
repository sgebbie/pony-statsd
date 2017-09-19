use "ponytest"

actor StatsDClientTests is TestList

	new create(env: Env) =>
		PonyTest(env, this)

	new make() =>
		None

	fun tag tests(test: PonyTest) =>
		test(_TestTimeAvg)
		test(_TestMetricCreation)
		test(_TestMetricAccumulate)

class iso _TestTimeAvg is UnitTest
	""" Checks the calculated average timer time. """

	fun name(): String => "statsd:time"

	fun apply(h: TestHelper) =>
		var v: I64 = 0
		var c: I64
		c = MILLISECONDS.convert(10, SECONDS)
		//h.env.out.print("10, seconds, " + c.string())
		v = v + c

		c = MILLISECONDS.convert(10, MILLISECONDS)
		//h.env.out.print("10, milliseconds, " + c.string())
		v = v + c

		c = MILLISECONDS.convert(1000, NANOSECONDS)
		//h.env.out.print("1000, nanoseconds, " + c.string())
		v = v + c

		c = MILLISECONDS.convert(100, MICROSECONDS)
		//h.env.out.print("100, microseconds, " + c.string())
		v = v + c

		c = MILLISECONDS.convert(50, SECONDS)
		//h.env.out.print("50, seconds, " + c.string())
		v = v + c

		c = MILLISECONDS.convert(10, MINUTES)
		//h.env.out.print("10, minutes, " + c.string())
		v = v + c

		c = MILLISECONDS.convert(5, HOURS)
		//h.env.out.print("5, hours, " + c.string())
		v = v + c

		c = MILLISECONDS.convert(1, DAYS)
		//h.env.out.print("1, days, " + c.string())
		v = v + c

		h.assert_eq[I64](105060010, v)
		h.assert_eq[I64](13132501, v/8)

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

	let _stringeq: {(String,String):Bool} val = {(lhs:String,rhs:String):Bool => lhs == rhs} val

	fun name(): String => "statsd:metric-accumulation"

	fun apply(h: TestHelper) =>
		h.long_test(1_000_000_000)
		let acc: StatsDTransportArray = StatsDTransportArray
		let statsd: StatsD = StatsD(StatsDAccumulator(where transport = acc))
		let client: StatsDClient = StatsDClient(statsd)
		client.doStuff({()(h,acc,_stringeq) =>
			statsd.flush({()(h,acc,_stringeq) =>
				// (but we might still get a timing issue between updates and flush)
				acc.snapshot({(lines: Array[String] iso)(h,_stringeq) =>
					let ll: Array[String] ref = consume lines
					// for l in ll.values() do h.env.out.>write(">>").>write(l).>print("<<") end
					h.assert_true(ll.contains("my.counter:513|c", _stringeq))
					h.assert_true(ll.contains("my.gauge:505|g", _stringeq))
					h.assert_true(ll.contains("my.set:5|s", _stringeq))
					h.assert_true(ll.contains("my.set:52|s", _stringeq))
					h.assert_true(ll.contains("my.timer:13132501|ms", _stringeq)) // see _TestTimeAvg
					h.complete(true)
				} val)
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

	be doStuff(completion: {()} val = Completion.nop()) =>
		count.now(513)
		gauge.>inc(5).>dec(7).>set(500).>inc(5)
		timer.>was(10,SECONDS).>ms(10).>nanos(1000).>micros(100).>sec(50).>min(10).>hr(5).>day(1)
		set.>add(5).>add(52)
		completion()
