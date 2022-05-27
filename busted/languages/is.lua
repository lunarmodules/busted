local s = require('say')

s:set_namespace('is')

-- 'Pending: test.lua @ 12 \n description
s:set('output.pending', 'Í bið')
s:set('output.failure', 'Bilun')
s:set('output.error', 'Villa')
s:set('output.success', 'Tókst')

s:set('output.pending_plural', 'í bið')
s:set('output.failure_plural', 'bilanir')
s:set('output.error_plural', 'villur')
s:set('output.success_plural', 'tókst')

s:set('output.pending_zero', 'í bið')
s:set('output.failure_zero', 'bilanir')
s:set('output.error_zero', 'villur')
s:set('output.success_zero', 'tókst')

s:set('output.pending_single', 'í bið')
s:set('output.failure_single', 'bilun')
s:set('output.error_single', 'villa')
s:set('output.success_single', 'tókst')

s:set('output.seconds', 'sekúndur')

s:set('output.no_test_files_match', 'Engar prufuskrár fundust sem passa við Lúa mynstur: %s')
s:set('output.file_not_found', 'Get ekki fundið skrá eða möppu: %s')

-- definitions following are not used within the 'say' namespace
return {
  failure_messages = {
    'Þú hefur %d brotnar fyrirmyndir',
    'Fyrirmyndirnar þínar eru brotnar',
    'Kóðinn þinn er slæmur og þér ætti að líða illa',
    'Í hvert skipti sem það er bilun skaltu drekka annan bjór',
  },
  success_messages = {
    'Húrra!',
    'Frábært!',
    'Geggjað!',
  }
}
