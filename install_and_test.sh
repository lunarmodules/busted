sudo luarocks make busted-1.5-1.rockspec
busted -o tap spec/ev_spec.lua
busted -o tap spec/copas_spec.lua
