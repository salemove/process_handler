# ProcessHandler

[![Code Climate](https://codeclimate.com/github/salemove/process_handler/badges/gpa.svg)](https://codeclimate.com/github/salemove/process_handler)

ProcessHandler helps to spawn and manage services. There are multiple types of processes. Every process knows how to handle `SIGINT` and `SIGTERM` signals.

## PivotProcess
This process is used for services that need one or more threads and use the request-response model.

Example of using pivot process:
```ruby
  service = MyService.new
  messenger = MyMessenger.new

  process = Salemove::ProcessHandler::PivotProcess.new(messenger, threads_count: 5)
  process.spawn(service)
```

### Messenger
See `Salemove::ProcessHandler::MockMessenger` for sample implementation. This is compatible with [Freddy](https://github.com/salemove/freddy).

### Service
If you want to use pivot process, then the given service must implement `call` method that takes `input` as an argument.

Example of a service:
```ruby
  class Echo
    def call(input)
      result = # do something with input
      {success: true, output: result} # return result
    end
  end
end
```

## CronProcess
This process allows a service to run recurringly either at times specified by a [cron expression](http://en.wikipedia.org/wiki/Cron#CRON_expression) or at a fixed time interval: "1" for seconds, "2h" for hours and "2d" for days.

Example of using cron process with cron expressions:
```ruby
  service = MyService.new

  # every five minutes between 7:00 and 7:55 on Mon to Fri
  process = Salemove::ProcessHandler::CronProcess.new('0/5 7  * * 1-5')
  process.spawn(service)
```

Example of using cron process with interval expressions:
```ruby
  service = MyService.new

  # every second hour
  process = Salemove::ProcessHandler::CronProcess.new('2h')
  process.spawn(service)
```

## Service
If you want to use a cron process, then you only must implement `call` method that does not take any arguments.

Example of a service:
```ruby
  class MemWatcher
    def call
      result = `sysctl -a | grep 'hw.usermem'`

      # e.g write this result to a file
    end
  end
```
