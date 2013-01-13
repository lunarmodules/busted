-- Expose luassert elements as part of global interfcae
assert = require('luassert')
spy    = require('luassert.spy')
mock   = require('luassert.mock')
stub   = require('luassert.stub')

-- Load and expose busted core as part of global interface
local busted = require('busted.core')
it          = busted.it
describe    = busted.describe
pending     = busted.pending
setup       = busted.setup
teardown    = busted.teardown
before_each = busted.before_each
after_each  = busted.after_each

return busted