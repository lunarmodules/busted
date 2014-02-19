-- Expose luassert elements as part of global interface
assert = require('luassert')
spy    = require('luassert.spy')
mock   = require('luassert.mock')
stub   = require('luassert.stub')

-- Assign default value for strict lua syntax checking
_TEST  = nil

-- Load and expose busted core as part of global interface
local busted = require('busted.core')

it          = busted.it
describe    = busted.describe
context     = busted.describe
pending     = busted.pending
setup       = busted.setup
teardown    = busted.teardown
before_each = busted.before_each
after_each  = busted.after_each
setloop     = busted.setloop
async       = busted.async

return busted
