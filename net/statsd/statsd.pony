"""StatsD telemetry collection."""
use time = "time"
use "net"

/* See: https://github.com/etsy/statsd/blob/master/docs/metric_types.md */

class val StatsD
	""" A factory for metrics. """

	let _statsd: StatsDAccumulator

	new val create_acc(statsd: StatsDAccumulator = StatsDAccumulator) =>
		_statsd = statsd

	new val create_trans(transport: StatsDTransport, timers: time.Timers = time.Timers) =>
		_statsd = StatsDAccumulator(where transport = transport, timers = timers)

	new val create_server(auth: UDPSocketAuth
									, server: NetAddress
									, timers: time.Timers = time.Timers) =>
		let transport = StatsDTransportUDP(auth, server)
		_statsd = StatsDAccumulator(where transport = transport, timers = timers)

	new val create(auth: (UDPSocketAuth & DNSLookupAuth)
									, host: String = "localhost", service: String = "8125"
									, timers: time.Timers = time.Timers)? =>
		let server = DNS(auth, host, service)(0)?
		let transport = StatsDTransportUDP(auth, server)
		_statsd = StatsDAccumulator(where transport = transport, timers = timers)

	fun val dispose() =>
		_statsd.dispose()

	fun val flush(completion: {()} val = Completion.nop()) =>
		_statsd._flush(where completion = completion)

	fun val gauge(bucket: String,
			initial_value: I64): Gauge val^ =>
		(recover val Gauge(_statsd, bucket) end)
			.>set(initial_value)

	fun val counter(bucket: String,
			initial_value: I64 = 0, sample_ratio: F32 = 0.0): Counter val^ =>
		(recover val Counter(_statsd, bucket, sample_ratio) end)
			.>now(initial_value)

	fun val timer(bucket: String, time_unit: TimeUnit = MILLISECONDS,
			sample_ratio: F32 = 0.0): Timer val^ =>
		recover val Timer(_statsd, bucket, time_unit, sample_ratio) end
		// note, we don't record an initial value since this will skew the averages

	fun val set(bucket: String): Set val^ =>
		recover val Set(_statsd, bucket) end
