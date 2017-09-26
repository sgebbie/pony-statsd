use "ponytest"
use "net"
use time = "time"

actor StatsDTests is TestList

	new create(env: Env) =>
		PonyTest(env, this)

	new make() =>
		None

	fun tag tests(test: PonyTest) =>
		test(_TestCreateAndEmit)

class iso _TestCreateAndEmit is UnitTest
	"""Tests sending via UDP transport."""

	var _statsd: (StatsD | None)
	var _mock: (UDPSocket | None)

	new iso create() =>
		_statsd = None
		_mock = None

	fun name(): String => "statsd:lifecycle"

	fun tear_down(h: TestHelper) =>
		// dispose
		match _statsd
		| let f: StatsD => f.dispose()
		end
		match _mock
		| let f: UDPSocket => f.dispose()
		end

	fun ref apply(h: TestHelper) =>
		h.long_test(1_000_000_000)
		try
			// set up client
			let port = "18126"
			let statsd: StatsD = StatsD.create(h.env.root as AmbientAuth, "localhost", port)?
			_statsd = statsd // record for teardown

			// capture in mock
			let notify: UDPNotify iso = object iso is UDPNotify
				var _count: U32 = 0
				let _gauge: Gauge = statsd.gauge("test.gauge.bucket", 0)
				let _set: Set = statsd.set("test.set.bucket")
				fun ref not_listening(sock: UDPSocket ref) =>
					h.fail("Server not able to listen")

				fun ref received(sock: UDPSocket ref, data: Array[U8] iso, from: NetAddress) =>
					// test results
					let text = String.from_array(consume data)
					// h.env.out.print(">>>"+text+"<<<")
					h.assert_true(text.size() > 10)
					h.assert_true(text.contains("test.gauge.bucket:") or text.contains("test.set.bucket"))
					h.assert_true(text.contains("|g") or text.contains("|s"))
					_count = _count + 1
					if _count >= 1 then _success() end

				fun ref _success() => h.complete(true)

				fun ref listening(sock: UDPSocket ref) =>
					// make sure that the mock is listening before sending test traffic
					// send some metrics and flush
					var i: U32 = 0
					while i < 100 do
						_gauge.set(i.i64())
						_set.add(i.i64())
						i = i + 1
					end
					statsd.flush()
			end

			// set up mock server socket to receive UDP
			// 'ngrep -d any port 18125'
			let mock: UDPSocket = UDPSocket(h.env.root as AmbientAuth
				, consume notify, "localhost", port, StatsDTransportConstants.fastEthernetMTU())
			_mock = mock // record for teardown

		else
			h.complete(false)
		end
