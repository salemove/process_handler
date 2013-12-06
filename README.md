# ProcessHandler
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
Every messenger must respond to `#process` method that gives a block if there is an available message to process. If there isn't a message, then nothing should be returned.

Example of a mock messenger:
```ruby
  class Messenger
    def process(queue_name)
      if rand(2) == 1
        result = yield({text: rand(100).to_s})
        # do something with result
      end
    end
  end
```

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

## RecurringProcess
This process is used for services that work independently in one thread every X seconds. These services do not take an input.

Example of using recurring process:
```ruby
  service = MyService.new

  process = Salemove::ProcessHandler::RecurringProcess.new(refractory_period: 30)
  process.spawn(service)
```

## Service
If you want to use recurring process, then you only must implement `call` method that does not take any arguments.

Example of a service:
```ruby
  class MemWatcher
    def call
      result = `sysctl -a | grep 'hw.usermem'`

      # e.g write this result to a file
    end
  end
```
