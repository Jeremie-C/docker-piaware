# docker-piaware

PiAware ADSB feeder

## Environment Variables

| Environment Variable | Purpose | Default |
| -------------------- | ------- | ------- |
| `BEAST_HOST` | Required. IP/Hostname of a Mode-S/BEAST provider (readsb) |         |
| `BEAST_PORT` | Optional. TCP port number of Mode-S/BEAST provider (readsb) | `30005`   |
| `FEEDER_ID`  | Required. Your static UUID |  |
| `TZ`         | Optional. Your local timezone | `GMT` |
