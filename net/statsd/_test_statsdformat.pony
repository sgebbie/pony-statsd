/**
 * Pony StatsD Library
 * Copyright (c) 2017 - Stewart Gebbie. Licensed under the MIT licence.
 * vim: set ts=2 sw=0:
 */
use "pony_test"

actor StatsDFormatTests is TestList

	new create(env: Env) =>
		PonyTest(env, this)

	new make() =>
		None

	fun tag tests(test: PonyTest) =>
		test(_TestFormatGauge)
		test(_TestFormatCounter)
		test(_TestFormatTimer)
		test(_TestFormatSet)

class iso _TestFormatGauge is UnitTest
	""" Format statsd gauge ops. """

	fun name(): String => "statsd:format:gauge"

	fun apply(h: TestHelper) =>
		// first check the simple '+positive' case
		h.assert_eq[String]("my.gauge:1234|g", StatsDFormat("my.gauge", GaugeSet, 1234))
		h.assert_eq[String]("my.gauge:+1234|g", StatsDFormat("my.gauge", GaugeInc, 1234))
		h.assert_eq[String]("my.gauge:-1234|g", StatsDFormat("my.gauge", GaugeDec, 1234))

		// now check handling of '-negatives'
		h.assert_eq[String]("my.gauge:0|g\nmy.gauge:-1234|g", StatsDFormat("my.gauge", GaugeSet, -1234))
		h.assert_eq[String]("my.gauge:-1234|g", StatsDFormat("my.gauge", GaugeInc, -1234))
		h.assert_eq[String]("my.gauge:+1234|g", StatsDFormat("my.gauge", GaugeDec, -1234))

class iso _TestFormatCounter is UnitTest
	""" Format statsd counter ops. """

	fun name(): String => "statsd:format:counter"

	fun apply(h: TestHelper) =>
		h.assert_eq[String]("my.counter:10|c", StatsDFormat("my.counter", CounterAdd, 10))
		h.assert_eq[String]("my.counter:10|c|@0.1", StatsDFormat("my.counter", CounterAdd, 10, 0.1))
		h.assert_eq[String]("my.counter:-10|c|@0.1", StatsDFormat("my.counter", CounterAdd, -10, 0.1))

class iso _TestFormatTimer is UnitTest
	""" Format statsd timer ops. """

	fun name(): String => "statsd:format:timer"

	fun apply(h: TestHelper) =>
		h.assert_eq[String]("my.timer:10|ms", StatsDFormat("my.timer", TimerRecord, 10))
		h.assert_eq[String]("my.timer:10|ms|@0.1", StatsDFormat("my.timer", TimerRecord, 10, 0.1))
		h.assert_eq[String]("my.timer:-10|ms|@0.1", StatsDFormat("my.timer", TimerRecord, -10, 0.1))

class iso _TestFormatSet is UnitTest
	""" Format statsd set ops. """

	fun name(): String => "statsd:format:set"

	fun apply(h: TestHelper) =>
		h.assert_eq[String]("my.set:10|s", StatsDFormat("my.set", SetInclude, 10))
