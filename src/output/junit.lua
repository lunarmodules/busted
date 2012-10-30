local xml = require "pl.xml"

local hostname = assert ( io.popen ( "uname -n" ) ):read ( "*l" )

return function ()
	local node
	return {
		header = function(context_tree)
			node = xml.new("testsuite",{
				errors    = 0 ;
				failures  = 0 ;
				hostname  = hostname ;
				name      = context_tree.description ;
				tests     = 0 ;
				--time      = ;
				timestamp = os.time ( ) ;
				skip      = 0 ;
			})
		end ;
		footer = function(context_tree)
		end ;
		formatted_status = function(statuses, options, ms)
			node.attr.time = ms
			return xml.tostring ( node , "" , "\t" )
		end ;
		currently_executing = function(test_status, options,...)
			-- Update counters
			node.attr.tests = node.attr.tests + 1
			if test_status.type == "failure" then
				node.attr.failures = node.attr.failures + 1
			end
			-- Edit node
			node:addtag ( "testcase" , {
					classname = test_status.info.short_src .. ":" .. test_status.info.linedefined;
					name      = test_status.description ;
					--time      = ;
				})
			if test_status.type == "failure" then
				node:addtag ( "failure" , {
						message = test_status.err ;
						--type    = ;
					})
					:text ( test_status.trace )
					:up()
			end
			node:up()
		end ;
	}
end
