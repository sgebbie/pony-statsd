PONY_STATSD_SRC=$(wildcard net/statsd/*.pony)

pony-statsd: $(PONY_STATSD_SRC)
	ponyc -b pony-statsd net/statsd

clean:
	rm -f pony-statsd
