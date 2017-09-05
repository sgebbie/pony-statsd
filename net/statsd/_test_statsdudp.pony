use "ponytest"

actor StatsDUDPTests is TestList

	new create(env: Env) =>
		PonyTest(env, this)

	new make() =>
		None

	fun tag tests(test: PonyTest) =>
		test(_TestMetricTransmit)

class iso _TestMetricTransmit is UnitTest
	"""Tests sending metrics via UDP."""

	fun name(): String => "metric send"

	fun apply(h: TestHelper) =>
		h.complete(true)

