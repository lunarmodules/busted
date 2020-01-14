std             = "max+busted"
unused_args     = false
redefined       = false
max_line_length = false


globals = {
    "randomize",
    "match",
    "async",
    "done",
    "busted",
    --"ngx.IS_CLI",
}


not_globals = {
    "string.len",
    "table.getn",
}


ignore = {
    --"6.", -- ignore whitespace warnings
}


exclude_files = {
    "install/**",
    "spec/insulate-expose_spec.lua",
    "spec/cl_compile_fail.lua",
}

