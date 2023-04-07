busted
======

[![Join the chat at https://gitter.im/lunarmodules/busted](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/lunarmodules/busted?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Busted](https://img.shields.io/github/actions/workflow/status/lunarmodules/busted/busted.yml?label=Busted&logo=Lua)](https://github.com/lunarmodules/busted/actions?workflow=Busted)
[![Luacheck](https://img.shields.io/github/actions/workflow/status/lunarmodules/busted/luacheck.yml?label=Luacheck&logo=Lua)](https://github.com/lunarmodules/busted/actions?workflow=Luacheck)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/lunarmodules/busted?label=Tag&logo=GitHub)](https://github.com/lunarmodules/busted/releases)
[![Luarocks](https://img.shields.io/luarocks/v/lunarmodules/busted?label=Luarocks&logo=Lua)](https://luarocks.org/modules/lunarmodules/busted)


busted is a unit testing framework with a focus on being **easy to
use**. Supports Lua >= 5.1, luajit >= 2.0.0, and moonscript.

Check out the [official docs](https://lunarmodules.github.io/busted/) for
extended info.

busted test specs read naturally without being too verbose. You can even
chain asserts and negations, such as `assert.is_not.equal`. Nest blocks of
tests with contextual descriptions using `describe`, and add tags to
blocks so you can run arbitrary groups of tests.

An extensible assert library allows you to extend and craft your own
assert functions specific to your case with method chaining. A modular
output library lets you add on your own output format, along with the
default pretty and plain terminal output, JSON with and without
streaming, and TAP-compatible output that allows you to run busted specs
within most CI servers.

```lua
describe('Busted unit testing framework', function()
  describe('should be awesome', function()
    it('should be easy to use', function()
      assert.truthy('Yup.')
    end)

    it('should have lots of features', function()
      -- deep check comparisons!
      assert.same({ table = 'great'}, { table = 'great' })

      -- or check by reference!
      assert.is_not.equals({ table = 'great'}, { table = 'great'})

      assert.falsy(nil)
      assert.error(function() error('Wat') end)
    end)

    it('should provide some shortcuts to common functions', function()
      assert.unique({{ thing = 1 }, { thing = 2 }, { thing = 3 }})
    end)

    it('should have mocks and spies for functional tests', function()
      local thing = require('thing_module')
      spy.on(thing, 'greet')
      thing.greet('Hi!')

      assert.spy(thing.greet).was.called()
      assert.spy(thing.greet).was.called_with('Hi!')
    end)
  end)
end)
```

Contributing
------------

See [CONTRIBUTING.md](https://github.com/lunarmodules/busted/blob/master/CONTRIBUTING.md).
All issues, suggestions, and most importantly pull requests are welcome.

Testing
-------

Assuming you have luarocks installed:

Install these dependencies for core testing:

```
luarocks install moonscript
```

Then to reinstall and run tests:

```
luarocks remove busted --force
luarocks make
busted spec
```

Docker
------

Alternatively Busted can be run as a standalone docker container.
This approach is somewhat limited because many projects will require extra dependencies which will need to be installed inside the Docker container.
Luarocks is provided in the container so many dependencies can be added.
The images are based on Alpine Linux so you can also use `apk add` to install system dependencies if needed.
The Docker use case is probably most advantageous for pure-Lua projects with no dependencies: i.g. small libraries not large apps.

The usage of docker is fairly simple.
You can either build your own or download a prebuilt version.
To build your own, execute the following command from the source directory of this project:

```console
$ docker build -t ghcr.io/lunarmodules/busted:HEAD .
```

To use a prebuilt one, download it from the GitHub Container Registry.
Here we use the one tagged *latest*, but you can substitute *latest* for any tagged release.

```console
$ docker pull ghcr.io/lunarmodules/busted:latest
```

Once you have a container you can run it on one file or a source tree (substitute *latest* with *HEAD* if you built your own or with the tagged version you want if applicable):

```console
# Run on an entire project
$ docker run -v "$(pwd):/data" ghcr.io/lunarmodules/busted:latest

# Run on one directory:
$ docker run -v "$(pwd):/data" ghcr.io/lunarmodules/busted:latest specs
```

A less verbose way to run it in most shells is with at alias:

```console
# In a shell or in your shell's RC file:
$ alias busted='docker run -v "$(pwd):/data" ghcr.io/lunarmodules/busted:latest'

# Thereafter just run:
$ busted
```
### Use as a CI job

There are actually many ways to run Busted remotely as part of a CI work flow.
Because packages are available for many platforms, one way would be to just use your platforms native package installation system to pull them into whatever CI runner environment you already use.
Another way is to pull in the prebuilt Docker container and run that.

As a case study, here is how a workflow could be setup in GitHub Actions:

```yaml
name: Busted
on: [push, pull_request]
jobs:
  sile:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Run Busted
        uses: lunarmodules/busted@v0
```

By default the GH Action is configured to run `busted --verbose`, but you can also pass it your own `args` to replace the default input of `.`.

```yaml
      - name: Run Busted
        uses: lunarmodules/busted@v0
        with:
            args: --tags=MYTAGS
```

License
-------

Copyright 2012-2020 Olivine Labs, LLC.
MIT licensed. See [LICENSE for details](https://github.com/lunarmodules/busted/blob/master/LICENSE).
