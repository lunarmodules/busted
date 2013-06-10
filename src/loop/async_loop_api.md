#Asynchronous loop API

The API for implementing your own loop with busted is fairly simple. It uses only two methods.

1. settimeout(seconds, callback)
1. step()

## create_timer(seconds, callback)
This (optional) method should create a `timer` object. The object should have a single method `stop` to cancel the timer. And after the period of `seconds` number of seconds has elapsed, it should call `callback()` (the callback does not take any parameters).

If you do not provide a `create_timer` method, then  busted might hang on faulty tests. A test will generally only exit on;

1. success
2. failure (explicit, eg. an `error` or `assert` call, caught by the `async` callback wrapper)
3. on timeout

So if you do not provide a `create_timer` method and a test neither fails nor succeeds, it will hang.

The default loop has a timer implementation that can be reused for coroutine based schedulers. See the `busted.loop.copas` module for an example. If you do a event framework similar as Lua-ev, then you should use timers as provided by that framework. In that case see the `busted.loop.ev` module for an example.

##step()
This method should execute a single step in the async loop for the framework it supports. In between executing steps, busted will check for test results and commence to the next test when required.

#Using a loop
To use your custom loop you can use the `setloop` method. `setloop` takes 1 parameters which is either a module name (eg. `setloop('copas')` to load the `busted.loop.copas` module) or a table providing the loop methods.

```lua
-- example providing your own loop in a test file

setloop({
  settimeout = function(sec,cb)
    -- some implementation here
  end,
  step = function()
    -- do an async step here
  end
})

-- or use an existing loop, in which case busted will load the loop module
setloop('copas')

````
