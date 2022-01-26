local s = require('say')

s:set_namespace('ro')

-- 'Pending: test.lua @ 12 \n description
s:set('output.pending', 'În așteptare')
s:set('output.failure', 'Eșec')
s:set('output.error', 'Eroare')
s:set('output.success', 'Succes')

s:set('output.pending_plural', 'în așteptare')
s:set('output.failure_plural', 'eșecuri')
s:set('output.error_plural', 'erori')
s:set('output.success_plural', 'succese')

s:set('output.pending_zero', 'în așteptare')
s:set('output.failure_zero', 'eșecuri')
s:set('output.error_zero', 'erori')
s:set('output.success_zero', 'succese')

s:set('output.pending_single', 'în așteptare')
s:set('output.failure_single', 'eșec')
s:set('output.error_single', 'eroare')
s:set('output.success_single', 'succes')

s:set('output.seconds', 'secunde')

s:set('output.no_test_files_match', 'Niciun fișier de testare găsit care să se potrivească cu tiparul Lua: %s')
s:set('output.file_not_found', 'Nu pot găsi fișierul sau folderul: %s')

-- definitions following are not used within the 'say' namespace
return {
  failure_messages = {
    'Ai %d teste praf',
    'Testele tale sunt varză',
    'Codul tău este rău și ar trebui să te simți rău',
    'Codul tău este în Zona Periculoasă',
    'Ce joc ciudat. Singura cale de a câștiga este să nu testezi',
    'Bunica mea scria teste mai bune pe un 3 86',
    'De fiecare dată când este un eșec, bea incă o bere',
    'Se simte rău omule'
  },
  success_messages = {
    'Ooo da, trec testele',
    'Nu contează, am avut teste',
    'Se simte bine, omule',
    'Grozav succes',
    'Testele trec, bea altă bere',
  }
}
