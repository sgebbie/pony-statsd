/**
 * Pony StatsD Library
 * Copyright (c) 2017 - Stewart Gebbie. Licensed under the MIT licence.
 * vim: set ts=2 sw=0:
 */
use "net"

class StatsDTransportUDPNotifier is UDPNotify
	fun ref not_listening(sock: UDPSocket ref) => None

actor StatsDTransportUDP
	"""
	A UDP emitter of metrics.

	```
	let udp_transport = StatsDTransportUDP(env.root as AmbientAuth
												, DNS(env.root as AmbientAuth, "localhost", "8125")(0)?)
	```
	"""

	let _nop_completion: {()} val
	let _new_line: U8
	let _mtu: USize
	let _statsd_socket: UDPSocket
	let _statsd_server: NetAddress
	let _level: {(USize)} val
	// we were using 'var _buf: Array[String] iso' and 'var _used: USize' together with
	// 'let b: Array[String] val = _buf = recover iso Array[String] end', under the assumption that writev still created
	// a single packet however, each ByteSeq in ByteSeqIter is sent as a separate UDP packet :(
	var _buf: String iso

	new create(auth: UDPSocketAuth, server: NetAddress, mtu: USize = StatsDTransportConstants.fastEthernetMTU(), level: {(USize)} val = {(l:USize) => None} val) =>
		_level = consume level
		_new_line = '\n'
		_nop_completion = Completion.nop()
		_mtu = mtu
		_statsd_server = server
		_statsd_socket = UDPSocket(auth, recover StatsDTransportUDPNotifier end where size = mtu)
		_buf = recover iso String(_mtu) end
		_level(_buf.size())

	be emit(bucket: String, op: MetricOp, value: I64, sample_ratio: F32 = 0.0, completion: {()} val = Completion.nop()) =>
		// build the line protocol string
		let l: String = StatsDFormat(bucket, op, value, sample_ratio)
		// check if it will fit in the current packet
		let extra: USize = l.size() + 1 /* 1 = size of new line */
		if (extra + _buf.size()) > _mtu then
			_flush(_nop_completion)
		end
		// append new line and metric line
		if _buf.size() > 0 then _buf.push(_new_line) end
		_buf.append(l)
		_level(_buf.size())
		// signal handled
		completion()

	be flush(completion: {()} val = Completion.nop()) =>
		_flush(completion)

	be dispose() =>
			_statsd_socket.dispose()

	fun ref _flush(completion: {()} val = Completion.nop()) =>
		if _buf.size() > 0 then
			// write the buffered lines to the UDP socket
			let b: String val = _buf = recover iso String(_mtu) end
			_statsd_socket.write(b, _statsd_server)
			_level(_buf.size())
		end
		completion()
