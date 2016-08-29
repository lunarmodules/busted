assert.is_nil(package.loaded.pl)
assert.is_nil(package.loaded['pl.file'])

describe('Tests insulation', function()
  insulate('environment inside insulate', function()
    pl = require 'pl'
    _G.insuated_global = true

    it('updates insuated global table _G', function()
      assert.is_not_nil(insuated_global)
      assert.is_not_nil(_G.insuated_global)
    end)

    it('updates package.loaded', function()
      assert.is_not_nil(pl)
      assert.is_not_nil(Date)
      assert.is_not_nil(package.loaded.pl)
      assert.is_not_nil(package.loaded['pl.Date'])
    end)
  end)

  describe('environment after insulate', function()
    it('restores insuated global table _G', function()
      assert.is_nil(insuated_global)
      assert.is_nil(_G.insuated_global)
    end)

    it('restores package.loaded', function()
      assert.is_nil(pl)
      assert.is_nil(Date)
      assert.is_nil(package.loaded.pl)
      assert.is_nil(package.loaded['pl.Date'])
    end)
  end)
end)

insulate('', function()
  describe('Tests expose', function()
    insulate('inside insulate block', function()
      expose('tests environment inside expose block', function()
        pl = require 'pl'
        exposed_global = true
        _G.global = true

        it('creates exposed global', function()
          assert.is_not_nil(exposed_global)
          assert.is_nil(_G.exposed_global)
        end)

        it('updates global table _G', function()
          assert.is_not_nil(global)
          assert.is_not_nil(_G.global)
        end)

        it('updates package.loaded', function()
          assert.is_not_nil(pl)
          assert.is_not_nil(Date)
          assert.is_not_nil(package.loaded.pl)
          assert.is_not_nil(package.loaded['pl.Date'])
        end)
      end)
    end)

    describe('neutralizes insulation', function()
      it('creates exposed global in outer block', function()
        assert.is_not_nil(exposed_global)
        assert.is_nil(_G.exposed_global)
      end)

      it('does not restore global table _G', function()
        assert.is_not_nil(global)
        assert.is_not_nil(_G.global)
      end)

      it('does not restore package.loaded', function()
        assert.is_not_nil(pl)
        assert.is_not_nil(Date)
        assert.is_not_nil(package.loaded.pl)
        assert.is_not_nil(package.loaded['pl.Date'])
      end)
    end)
  end)

  it('Tests exposed globals does not exist in outer most block', function()
    assert.is_nil(pl)
    assert.is_nil(exposed_global)
    assert.is_nil(_G.exposed_global)
  end)

  it('Tests global table _G persists without insulate', function()
    assert.is_not_nil(global)
    assert.is_not_nil(_G.global)
  end)

  it('Tests package.loaded persists without insulate', function()
    assert.is_not_nil(Date)
    assert.is_not_nil(package.loaded.pl)
    assert.is_not_nil(package.loaded['pl.Date'])
  end)
end)

describe('Tests after insulating an expose block', function()
  it('restores global table _G', function()
    assert.is_nil(global)
    assert.is_nil(_G.global)
  end)

  it('restores package.loaded', function()
    assert.is_nil(pl)
    assert.is_nil(Date)
    assert.is_nil(package.loaded.pl)
    assert.is_nil(package.loaded['pl.Date'])
  end)
end)

describe('Tests insulate/expose', function()
  local path = require 'pl.path'
  local utils = require 'pl.utils'
  local busted_cmd = path.is_windows and 'lua bin/busted' or 'bin/busted'

  local executeBusted = function(args)
    local success, exitcode, out, err = utils.executeex(busted_cmd .. ' ' .. args)
    if exitcode > 255 then
      exitcode = math.floor(exitcode/256), exitcode - math.floor(exitcode/256)*256
    end
    return not not success, exitcode, out, err
  end

  describe('file insulation', function()
    it('works between files', function()
      local success, exitcode = executeBusted('spec/insulate_file1.lua spec/insulate_file2.lua')
      assert.is_true(success)
      assert.is_equal(0, exitcode)
    end)

    it('works between files independent of order', function()
      local success, exitcode = executeBusted('spec/insulate_file2.lua spec/insulate_file1.lua')
      assert.is_true(success)
      assert.is_equal(0, exitcode)
    end)
  end)

  describe('expose from file context', function()
    it('works between files', function()
      local success, exitcode = executeBusted('spec/expose_file1.lua spec/expose_file2.lua')
      assert.is_true(success)
      assert.is_equal(0, exitcode)
    end)
  end)
end)
