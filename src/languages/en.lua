local s = require('say')

s:set_namespace("en")

-- "Pending: test.lua @ 12 \n description
s:set("output.pending", "Pending")
s:set("output.failure", "Failure")
s:set("output.success", "Success")

s:set("output.pending_plural", "pending")
s:set("output.failure_plural", "failures")
s:set("output.success_plural", "successes")

s:set("output.pending_zero", "pending")
s:set("output.failure_zero", "failures")
s:set("output.success_zero", "successes")

s:set("output.pending_single", "pending")
s:set("output.failure_single", "failure")
s:set("output.success_single", "success")

s:set("output.seconds", "seconds")

-- definitions following are not used within the 'say' namespace
return {
  failure_messages = {
    "You have %d busted specs",
    "Your specs are busted",
    "Your code is bad and you should feel bad",
    "Your code is in the Danger Zone",
    "Strange game. The only way to win is not to test",
    "My grandmother wrote better specs on a 3 86",
    "Every time there's a failure, drink another beer",
    "Feels bad man"
  },
  success_messages = {
    "Aww yeah, passing specs",
    "Doesn't matter, had specs",
    "Feels good, man",
    "Great success",
    "Tests pass, drink another beer",
  }
}
