use "ponytest"

actor StatsDClientTests is TestList

	new create(env: Env) =>
		PonyTest(env, this)

	new make() =>
		None

	fun tag tests(test: PonyTest) =>
		test(_TestMetricCreation)

class iso _TestMetricCreation is UnitTest
	"""Creates a client that allocates metrics."""

	fun name(): String => "metric creation"

	fun apply(h: TestHelper) =>
		h.complete(true)

actor StatsDClient

	let count: Counter val
	let gauge: Gauge val
	let timer: Timer val
	let set: Set val

	new create(statsd: StatsD val) =>
		count = statsd.counter(where bucket="my.counter", initial_value=0, sample_ratio=1.0)
		gauge = statsd.gauge(where bucket="my.gauge", initial_value=0)
		timer = statsd.timer(where bucket="my.timer", time_unit=MILLISECONDS, sample_ratio=1.0)
		set = statsd.set(where bucket="my.set")

 	be doStuff() =>
 		count.now(513)
 		gauge.>inc(5).>dec(7).>set(500)
 		timer.>was(10,SECONDS).>ms(10).>nanos(1000).>micros(100).>sec(50).>min(10).>hr(5).>day(1)
 		set.>add(5).>add(52)
		

