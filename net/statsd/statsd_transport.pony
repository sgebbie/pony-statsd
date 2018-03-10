/**
 * Pony StatsD Library
 * Copyright (c) 2017 - Stewart Gebbie. Licensed under the MIT licence.
 * vim: set ts=2 sw=0:
 */
primitive Completion
	fun nop():{()} val => {() => None} val

primitive StatsDTransportConstants
	// https://github.com/etsy/statsd/blob/master/docs/metric_types.md
	// payload sizes
	fun fastEthernetMTU(): USize => 1432
	fun gigbitEthernetMTU(): USize => 8932
	fun commodityEthernetMTU(): USize => 512

interface tag StatsDTransport
	""" An emitter of metrics. """

	be emit(bucket: String, op: MetricOp, value: I64, sample_ratio: F32 = 0.0, completion: {()} val = Completion.nop()) =>
		"""
		Buffer a measurement for transport.

		It might be sent if the buffer is full.
		"""
		completion()

/*
	be emit_batch(batch: Array[Measurement] val) =>
		""" Buffer all measurements for transport.

				It might force a flush of earlier measurements first in order
				to fit all of these measurements into one frame.
		"""
		// used to group gauge set=0 & set = negative into one frame
		None
*/

	be flush(completion: {()} val = Completion.nop()) =>
		""" Force the sending of all buffered measurements. """
		completion()

	be dispose() => None

actor StatsDTransportNop is StatsDTransport

actor StatsDTransportArray is StatsDTransport
	""" A simple 'mock' transport that retains statsd lines for later review. """

	let _lines: Array[String] ref

	new create() =>
		_lines = Array[String]

	be emit(bucket: String, op: MetricOp, value: I64, sample_ratio: F32 = 0.0, completion: {()} val = Completion.nop()) =>
		let l: String = StatsDFormat(bucket, op, value, sample_ratio)
		_lines.push(l)
		completion()

/*
	be emit_batch(batch: Array[Measurement] val) =>
		for m in batch.values() do
			match m
			| (let bucket: String, let op: MetricOp, let value: I64, let sample_ratio: F32) =>
				let l: String = StatsDFormat(bucket, op, value, sample_ratio)
				_lines.push(l)
			end
		end
*/

	be flush(completion: {()} val = Completion.nop()) =>
		""" Force the sending of all buffered measurements. """
		completion()

	be clear() =>
		_lines.clear()

	be visit(lines: {(String)} val) =>
		for l in _lines.values() do
			lines(l)
		end

	be snapshot(lines: {(Array[String] iso)} val) =>
		let s: USize = _lines.size()
		let copy: Array[String] iso = recover iso Array[String](s) end
		for l in _lines.values() do
			copy.push(l)
		end
		lines(consume copy)
