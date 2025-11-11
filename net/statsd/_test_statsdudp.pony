/**
 * Pony StatsD Library
 * Copyright (c) 2017 - Stewart Gebbie. Licensed under the MIT licence.
 * vim: set ts=2 sw=0:
 */
use "pony_test"
use "net"

actor StatsDUDPTests is TestList

	new create(env: Env) =>
		PonyTest(env, this)

	new make() =>
		None

	fun tag tests(test: PonyTest) =>
		test(_TestCreateUDPTransport)
		test(_TestTransmitUDP)

class iso _TestCreateUDPTransport is UnitTest
	"""Tests setup and teardown of UDP transport."""

	fun name(): String => "statsd:udpcreate"

	fun apply(h: TestHelper) =>
		h.long_test(1_000_000_000)
		try
			// set up mock to receive UDP
			let server: NetAddress = DNS(DNSAuth(h.env.root), "localhost", "18125")(0)?
			let trans: StatsDTransportUDP = StatsDTransportUDP(UDPAuth(h.env.root), server)
			// displose
			trans.dispose()
			h.complete(true)
		else
			h.complete(false)
		end

class iso _TestTransmitUDP is UnitTest
	"""Tests sending via UDP transport."""

	var _trans: (StatsDTransportUDP | None)
	var _mock: (UDPSocket | None)

	new iso create() =>
		_trans = None
		_mock = None

	fun name(): String => "statsd:udpsend"

	fun tear_down(h: TestHelper) =>
		// dispose
		match _trans
		| let f: StatsDTransportUDP => f.dispose()
		end
		match _mock
		| let f: UDPSocket => f.dispose()
		end

	fun ref apply(h: TestHelper) =>
		h.long_test(1_000_000_000)
		try
			// set up client
			let level: {(USize)} val = {(used: USize) => None /* h.env.out.print("used = " + used.string()) */ } val
			let server = DNS(DNSAuth(h.env.root), "localhost", "18125")(0)?
			let trans = StatsDTransportUDP(UDPAuth(h.env.root), server where level = consume level)
			_trans = trans // record for teardown

			// capture in mock
			let notify: UDPNotify iso = object iso is UDPNotify
				var _count: U32 = 0
				fun ref not_listening(sock: UDPSocket ref) =>
					h.fail("Server not able to listen")

				fun ref received(sock: UDPSocket ref, data: Array[U8] iso, from: NetAddress) =>
					// test results
					let text = String.from_array(consume data)
					//h.env.out.print(">>>"+text+"<<<")
					h.assert_true(text.size() > 100)
					h.assert_true(text.contains("test.bucket:"))
					h.assert_true(text.contains("|g"))
					_count = _count + 1
					if _count >= 2 then _success() end

				fun ref _success() => h.complete(true)

				fun ref listening(sock: UDPSocket ref) =>
					// make sure that the mock is listening before sending test traffic
					_send_test_traffic()

				fun ref _send_test_traffic() =>
					// send metrics (enough to fill two packets)
					var i: U32 = 0
					while i < 100 do
						trans.emit("test.bucket", GaugeSet, i.i64())
						i = i + 1
					end
					trans.flush()
			end

			// set up mock server socket to receive UDP
			// 'ngrep -d any port 18125'
			let mock: UDPSocket = UDPSocket(UDPAuth(h.env.root)
				, consume notify, "localhost", "18125", StatsDTransportConstants.fastEthernetMTU())
			_mock = mock // record for teardown

		else
			h.complete(false)
		end
