# Pony StatsD

This library provides the basic mechanisms for producing [StatsD][etsy-statsd]
telemetry from [Pony][ponylang] programmes.

# Basic Usage

```pony
let statsd: StatsD = StatsD.create(env.root as AmbientAuth, "statsd.host")?
let gauge: Gauge = statsd.gauge("test.gauge.bucket")

gauge.inc(5)
…
gauge.inc(2)
…
gauge.set(6)
```

[etsy-statsd]: https://github.com/etsy/statsd "Etsy StatsD Daemon"
[ponylang]: https://www.ponylang.org/ "Pony is an open-source, object-oriented, actor-model, capabilities-secure, high-performance programming language."
