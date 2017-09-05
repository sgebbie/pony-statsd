"""StatsD telemetry collection."""

/*

See: https://github.com/etsy/statsd/blob/master/docs/metric_types.md


Simply group into batches that fit in a given UDP packet and separate with \n

Within a batch local aggregation can be performed up to a given resolution.
 */

primitive NANOSECONDS
primitive MICROSECONDS
primitive MILLISECONDS
primitive SECONDS
primitive MINUTES
primitive HOURS
primitive DAYS
primitive YEARS

type TimeUnit is (
    NANOSECONDS | MICROSECONDS | MILLISECONDS | SECONDS 
 	| MINUTES | HOURS | DAYS | YEARS )

class iso Counter
"""
Count -
  "%s:%d|c" (bucket, value) or
  "%s:%d|c|@%f" (bucket, value, sample-ratio)
"""

	let _bucket: String
	let _samples: F32
	var _value: I64

	new iso create(bucket: String, initial_value: I64 = 0, sample_ratio: F32 = 0.0) =>
		_bucket = bucket
		_samples = sample_ratio
		_value = initial_value

	fun ref now(value: I64) =>
		_value = value

class iso Timer
"""
Duration -
	"%s:%d|ms" (bucket, value) or
  "%s:%d|ms|@%f" (bucket, value, sample-ratio)
"""
	let _bucket: String
	let _samples: F32
	let _time_unit: TimeUnit
	var _value: I64

	new iso create(bucket: String, initial_value: I64 = 0, time_unit: TimeUnit = MILLISECONDS, sample_ratio: F32 = 0.0) =>
		_bucket = bucket
		_samples = sample_ratio
		_time_unit = time_unit
		_value = initial_value

	fun ref was(value: I64, unit: TimeUnit) =>
		_value = value

	fun ref nanos(value: I64) => was(value, NANOSECONDS)
	fun ref micros(value: I64) => was(value, MICROSECONDS)
	fun ref ms(value: I64) => was(value, MILLISECONDS)
	fun ref sec(value: I64) => was(value, SECONDS)
	fun ref min(value: I64) => was(value, MINUTES)
	fun ref hr(value: I64) => was(value, HOURS)
	fun ref day(value: I64) => was(value, DAYS)
	fun ref yr(value: I64) => was(value, YEARS)

class iso Gauge
"""
Gauge -
  "%s:%d|g" (bucket, value) or
  "%s:+%d|g" (bucket, inc) or
  "%s:-%d|g" (bucket, dec)
"""

	let _bucket: String
	var _value: I64

	new iso create(bucket: String, initial_value: I64) =>
		_bucket = bucket
		_value = initial_value

	fun ref inc(value: I64) =>
		_value = _value + value

	fun ref dec(value: I64) =>
		_value = _value - value

	fun ref set(value: I64) =>
		_value = value

class iso Set
"""
Set -
  "%s:%d|s" (bucket, value)
"""
	let _bucket: String

	new iso create(bucket: String) =>
		_bucket = bucket

	fun ref add(value: I64) =>
		None

type Metric is (Counter | Gauge | Timer | Set)

actor StatsD

	fun val counter(bucket: String, initial_value: I64 = 0, sample_ratio: F32 = 0.0): Counter iso^ =>
		recover iso Counter(bucket, initial_value, sample_ratio) end

	fun val timer(bucket: String, initial_value: I64 = 0, time_unit: TimeUnit = MILLISECONDS, sample_ratio: F32 = 0.0): Timer iso^ =>
 		recover iso Timer(bucket, initial_value, time_unit, sample_ratio) end

 	fun val gauge(bucket: String, initial_value: I64): Gauge iso^ =>
 		recover iso Gauge(bucket, initial_value) end

 	fun val set(bucket: String): Set iso^ =>
 		recover iso Set(bucket) end

