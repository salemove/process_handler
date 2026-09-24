# Changelog

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the gem follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [5.0.0] - 2026-09-24

### Removed

- `CompositeProcess` and `start_composite`. Start each process with `PivotProcess` or `CronProcess` on its own.
- The Airbrake and Growl notifiers. A notifier config with the type `airbrake` or `growl` now gets no notifier. Use `sentry` or `terminal-notifier`.

### Changed

- The gem requires Ruby 3.3 or later.
- The gem declares `benchmark` and `logger` as runtime dependencies. Both leave Ruby's default gems in 3.5, so consumers need not add them to their own Gemfiles.
