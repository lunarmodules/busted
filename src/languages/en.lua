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

s:set("assertion.same.positive", "Expected objects to be the same. Passed in:\n%s\nExpected:\n%s")
s:set("assertion.same.negative", "Expected objects to not be the same. Passed in:\n%s\nDid not expect:\n%s")

s:set("assertion.equals.positive", "Expected objects to be equal. Passed in:\n%s\nExpected:\n%s")
s:set("assertion.equals.negative", "Expected objects to not be equal. Passed in:\n%s\nDid not expect:\n%s")

s:set("assertion.unique.positive", "Expected object to be unique:\n%s")
s:set("assertion.unique.negative", "Expected object to not be unique:\n%s")

s:set("assertion.error.positive", "Expected error to be thrown.")
s:set("assertion.error.negative", "Expected error to not be thrown.\n%s")

s:set("assertion.truthy.positive", "Expected to be truthy, but value was:\n%s")
s:set("assertion.truthy.negative", "Expected to not be truthy, but value was:\n%s")

s:set("assertion.falsy.positive", "Expected to be falsy, but value was:\n%s")
s:set("assertion.falsy.negative", "Expected to not be falsy, but value was:\n%s")

failure_messages = {
  "You have %d busted specs",
  "Your specs are busted",
  "Your code is bad and you should feel bad",
  "Your code is in the Danger Zone",
  "Strange game. The only way to win is not to test",
  "My grandmother wrote better specs on a 3 86",
  "Every time there's a failure, drink another beer",
  "Feels bad man"
}

success_messages = {
  "Aww yeah, passing specs",
  "Doesn't matter, had specs",
  "Feels good, man",
  "Great success",
  "Tests pass, drink another beer",
}
