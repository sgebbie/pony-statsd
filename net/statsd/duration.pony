/**
 * Pony StatsD Library
 * Copyright (c) 2017 - Stewart Gebbie. Licensed under the MIT licence.
 * vim: set ts=2 sw=0:
 */
// FIXME in order to comply with the ISO calendar standard we should rather use 1 year = 31556952 seconds (i.e. 365.2425 days)

primitive NANOSECONDS
	fun toNanos(t: I64): I64     => t
	fun toMicros(t: I64): I64    => t / 1_000
	fun toMillis(t: I64): I64    => t / 1_000_000
	fun toSeconds(t: I64): I64   => t / 1_000_000_000
	fun toMinutes(t: I64): I64   => t / (1_000_000_000 * 60)
	fun toHours(t: I64): I64     => t / (1_000_000_000 * 60 * 60)
	fun toDays(t: I64): I64      => t / (1_000_000_000 * 60 * 60 * 24)
	fun toYears(t: I64): I64     => t / (1_000_000_000 * 60 * 60 * 24 * 365)
	fun toDecades(t: I64): I64   => t / (1_000_000_000 * 60 * 60 * 24 * 365 * 10)
	fun toCenturies(t: I64): I64 => t / (1_000_000_000 * 60 * 60 * 24 * 365 * 100)
	fun toMillenia(t: I64): I64  => t / (1_000_000_000 * 60 * 60 * 24 * 365 * 1000)
	fun toEras(t: I64): I64      => t / (1_000_000_000 * 60 * 60 * 24 * 365 * 1000_000_000)
	fun convert(t: I64, u: TimeUnit): I64 => u.toNanos(t)

primitive MICROSECONDS
	fun toNanos(t: I64): I64     => t * 1_000
	fun toMicros(t: I64): I64    => t
	fun toMillis(t: I64): I64    => t / 1_000
	fun toSeconds(t: I64): I64   => t / 1_000_000
	fun toMinutes(t: I64): I64   => t / (1_000_000 * 60)
	fun toHours(t: I64): I64     => t / (1_000_000 * 60 * 60)
	fun toDays(t: I64): I64      => t / (1_000_000 * 60 * 60 * 24)
	fun toYears(t: I64): I64     => t / (1_000_000 * 60 * 60 * 24 * 365)
	fun toDecades(t: I64): I64   => t / (1_000_000 * 60 * 60 * 24 * 365 * 10)
	fun toCenturies(t: I64): I64 => t / (1_000_000 * 60 * 60 * 24 * 365 * 100)
	fun toMillenia(t: I64): I64  => t / (1_000_000 * 60 * 60 * 24 * 365 * 1000)
	fun toEras(t: I64): I64      => t / (1_000_000 * 60 * 60 * 24 * 365 * 1000_000_000)
	fun convert(t: I64, u: TimeUnit): I64 => u.toMicros(t)

primitive MILLISECONDS
	fun toNanos(t: I64): I64     => t * 1_000_000
	fun toMicros(t: I64): I64    => t * 1_000
	fun toMillis(t: I64): I64    => t
	fun toSeconds(t: I64): I64   => t / 1_000
	fun toMinutes(t: I64): I64   => t / (1_000 * 60)
	fun toHours(t: I64): I64     => t / (1_000 * 60 * 60)
	fun toDays(t: I64): I64      => t / (1_000 * 60 * 60 * 24)
	fun toYears(t: I64): I64     => t / (1_000 * 60 * 60 * 24 * 365)
	fun toDecades(t: I64): I64   => t / (1_000 * 60 * 60 * 24 * 365 * 10)
	fun toCenturies(t: I64): I64 => t / (1_000 * 60 * 60 * 24 * 365 * 100)
	fun toMillenia(t: I64): I64  => t / (1_000 * 60 * 60 * 24 * 365 * 1000)
	fun toEras(t: I64): I64      => t / (1_000 * 60 * 60 * 24 * 365 * 1000_000_000)
	fun convert(t: I64, u: TimeUnit): I64 => u.toMillis(t)

primitive SECONDS
	fun toNanos(t: I64): I64     => t * 1_000_000_000
	fun toMicros(t: I64): I64    => t * 1_000_000
	fun toMillis(t: I64): I64    => t * 1_000
	fun toSeconds(t: I64): I64   => t
	fun toMinutes(t: I64): I64   => t / (60)
	fun toHours(t: I64): I64     => t / (60 * 60)
	fun toDays(t: I64): I64      => t / (60 * 60 * 24)
	fun toYears(t: I64): I64     => t / (60 * 60 * 24 * 365)
	fun toDecades(t: I64): I64   => t / (60 * 60 * 24 * 365 * 10)
	fun toCenturies(t: I64): I64 => t / (60 * 60 * 24 * 365 * 100)
	fun toMillenia(t: I64): I64  => t / (60 * 60 * 24 * 365 * 1000)
	fun toEras(t: I64): I64      => t / (60 * 60 * 24 * 365 * 1000_000_000)
	fun convert(t: I64, u: TimeUnit): I64 => u.toSeconds(t)

primitive MINUTES
	fun toNanos(t: I64): I64     => t * 1_000_000_000 * 60
	fun toMicros(t: I64): I64    => t * 1_000_000 * 60
	fun toMillis(t: I64): I64    => t * 1_000 * 60
	fun toSeconds(t: I64): I64   => t * 60
	fun toMinutes(t: I64): I64   => t
	fun toHours(t: I64): I64     => t / (60)
	fun toDays(t: I64): I64      => t / (60 * 24)
	fun toYears(t: I64): I64     => t / (60 * 24 * 365)
	fun toDecades(t: I64): I64   => t / (60 * 24 * 365 * 10)
	fun toCenturies(t: I64): I64 => t / (60 * 24 * 365 * 100)
	fun toMillenia(t: I64): I64  => t / (60 * 24 * 365 * 1000)
	fun toEras(t: I64): I64      => t / (60 * 24 * 365 * 1000_000_000)
	fun convert(t: I64, u: TimeUnit): I64 => u.toMinutes(t)

primitive HOURS
	fun toNanos(t: I64): I64     => t * 1_000_000_000 * 60 * 60
	fun toMicros(t: I64): I64    => t * 1_000_000 * 60 * 60
	fun toMillis(t: I64): I64    => t * 1_000 * 60 * 60
	fun toSeconds(t: I64): I64   => t * 60 * 60
	fun toMinutes(t: I64): I64   => t * 60
	fun toHours(t: I64): I64     => t
	fun toDays(t: I64): I64      => t / (24)
	fun toYears(t: I64): I64     => t / (24 * 365)
	fun toDecades(t: I64): I64   => t / (24 * 365 * 10)
	fun toCenturies(t: I64): I64 => t / (24 * 365 * 100)
	fun toMillenia(t: I64): I64  => t / (24 * 365 * 1000)
	fun toEras(t: I64): I64      => t / (24 * 365 * 1000_000_000)
	fun convert(t: I64, u: TimeUnit): I64 => u.toHours(t)

primitive DAYS
	fun toNanos(t: I64): I64     => t * 1_000_000_000 * 60 * 60 * 24
	fun toMicros(t: I64): I64    => t * 1_000_000 * 60 * 60 *24
	fun toMillis(t: I64): I64    => t * 1_000 * 60 * 60 *24
	fun toSeconds(t: I64): I64   => t * 60 * 60 * 24
	fun toMinutes(t: I64): I64   => t * 60 * 24
	fun toHours(t: I64): I64     => t * 24
	fun toDays(t: I64): I64      => t
	fun toYears(t: I64): I64     => t / (365)
	fun toDecades(t: I64): I64   => t / (365 * 10)
	fun toCenturies(t: I64): I64 => t / (365 * 100)
	fun toMillenia(t: I64): I64  => t / (365 * 1000)
	fun toEras(t: I64): I64      => t / (365 * 1000_000_000)
	fun convert(t: I64, u: TimeUnit): I64 => u.toDays(t)

primitive YEARS
	fun toNanos(t: I64): I64     => t * 1_000_000_000 * 60 * 60 * 24 * 365
	fun toMicros(t: I64): I64    => t * 1_000_000 * 60 * 60 * 24 * 365
	fun toMillis(t: I64): I64    => t * 1_000 * 60 * 60 * 24 * 365
	fun toSeconds(t: I64): I64   => t * 60 * 60 * 24 * 365
	fun toMinutes(t: I64): I64   => t * 60 * 24 * 365
	fun toHours(t: I64): I64     => t * 24 * 365
	fun toDays(t: I64): I64      => t * 365
	fun toYears(t: I64): I64     => t
	fun toDecades(t: I64): I64   => t / (10)
	fun toCenturies(t: I64): I64 => t / (100)
	fun toMillenia(t: I64): I64  => t / (1000)
	fun toEras(t: I64): I64      => t / (1000_000_000)
	fun convert(t: I64, u: TimeUnit): I64 => u.toYears(t)

primitive DECADES
	fun toNanos(t: I64): I64     => t * 1_000_000_000 * 60 * 60 * 24 * 365 * 10
	fun toMicros(t: I64): I64    => t * 1_000_000 * 60 * 60 * 24 * 365 * 10
	fun toMillis(t: I64): I64    => t * 1_000 * 60 * 60 * 24 * 365 * 10
	fun toSeconds(t: I64): I64   => t * 60 * 60 * 24 * 365 * 10
	fun toMinutes(t: I64): I64   => t * 60 * 24 * 365 * 10
	fun toHours(t: I64): I64     => t * 24 * 365 * 10
	fun toDays(t: I64): I64      => t * 365 * 10
	fun toYears(t: I64): I64     => t * 10
	fun toDecades(t: I64): I64   => t
	fun toCenturies(t: I64): I64 => t / (10)
	fun toMillenia(t: I64): I64  => t / (100)
	fun toEras(t: I64): I64      => t / (100_000_000)
	fun convert(t: I64, u: TimeUnit): I64 => u.toDecades(t)

primitive CENTURIES
	fun toNanos(t: I64): I64     => t * 1_000_000_000 * 60 * 60 * 24 * 365 * 100
	fun toMicros(t: I64): I64    => t * 1_000_000 * 60 * 60 * 24 * 365 * 100
	fun toMillis(t: I64): I64    => t * 1_000 * 60 * 60 * 24 * 365 * 100
	fun toSeconds(t: I64): I64   => t * 60 * 60 * 24 * 365 * 100
	fun toMinutes(t: I64): I64   => t * 60 * 24 * 365 * 100
	fun toHours(t: I64): I64     => t * 24 * 365 * 100
	fun toDays(t: I64): I64      => t * 365 * 100
	fun toYears(t: I64): I64     => t * 100
	fun toDecades(t: I64): I64   => t * 10
	fun toCenturies(t: I64): I64 => t
	fun toMillenia(t: I64): I64  => t / (10)
	fun toEras(t: I64): I64      => t / (10_000_000)
	fun convert(t: I64, u: TimeUnit): I64 => u.toCenturies(t)

primitive MILLENIA
	fun toNanos(t: I64): I64     => t * 1_000_000_000 * 60 * 60 * 24 * 365 * 1000
	fun toMicros(t: I64): I64    => t * 1_000_000 * 60 * 60 * 24 * 365 * 1000
	fun toMillis(t: I64): I64    => t * 1_000 * 60 * 60 * 24 * 365 * 1000
	fun toSeconds(t: I64): I64   => t * 60 * 60 * 24 * 365 * 1000
	fun toMinutes(t: I64): I64   => t * 60 * 24 * 365 * 1000
	fun toHours(t: I64): I64     => t * 24 * 365 * 1000
	fun toDays(t: I64): I64      => t * 365 * 1000
	fun toYears(t: I64): I64     => t * 1000
	fun toDecades(t: I64): I64   => t * 100
	fun toCenturies(t: I64): I64 => t * 10
	fun toMillenia(t: I64): I64  => t
	fun toEras(t: I64): I64      => t / (1_000_000)
	fun convert(t: I64, u: TimeUnit): I64 => u.toMillenia(t)

primitive ERAS
	fun toNanos(t: I64): I64     => t * 1_000_000_000 * 60 * 60 * 24 * 365 * 1000_000_000
	fun toMicros(t: I64): I64    => t * 1_000_000 * 60 * 60 * 24 * 365 * 1000_000_000
	fun toMillis(t: I64): I64    => t * 1_000 * 60 * 60 * 24 * 365 * 1000_000_000
	fun toSeconds(t: I64): I64   => t * 60 * 60 * 24 * 365 * 1000_000_000
	fun toMinutes(t: I64): I64   => t * 60 * 24 * 365 * 1000_000_000
	fun toHours(t: I64): I64     => t * 24 * 365 * 1000_000_000
	fun toDays(t: I64): I64      => t * 365 * 1000_000_000
	fun toYears(t: I64): I64     => t * 1000_000_000
	fun toDecades(t: I64): I64   => t * 100_000_000
	fun toCenturies(t: I64): I64 => t * 10_000_000
	fun toMillenia(t: I64): I64  => t * 1_000_000
	fun toEras(t: I64): I64      => t
	fun convert(t: I64, u: TimeUnit): I64 => u.toEras(t)

type TimeUnit is (
    NANOSECONDS | MICROSECONDS | MILLISECONDS | SECONDS
 	| MINUTES | HOURS | DAYS | YEARS | DECADES | CENTURIES | MILLENIA | ERAS)

