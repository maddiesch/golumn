# Golumn

Something for all your precious logs.

```ruby
Rails.logger.extend(
  ActiveSupport::Logger.broadcast(
    ActiveSupport::TaggedLogging.new(Golumn::Targets::CloudWatch.new)
  )
)
```
