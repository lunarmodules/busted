local s = require('say')

s:set_namespace("ru")

-- "Pending: test.lua @ 12 \n description
s:set("output.pending", "Ожидает")
s:set("output.failure", "Поломалcя")
s:set("output.success", "Прошeл")

s:set("output.pending_plural", "ожидают")
s:set("output.failure_plural", "поломалиcь")
s:set("output.success_plural", "прошли")

s:set("output.pending_zero", "ожидающих")
s:set("output.failure_zero", "поломанных")
s:set("output.success_zero", "прошедших")

s:set("output.pending_single", "ожидает")
s:set("output.failure_single", "поломался")
s:set("output.success_single", "прошел")

s:set("output.seconds", "секунд")

s:set("assertion.same.positive", "Ожидали одинаковые объекты. Передали:\n%s\nОжидали:\n%s")
s:set("assertion.same.negative", "Ожидали разные объекты. Передали:\n%s\nНе ожидали:\n%s")

s:set("assertion.equals.positive", "Ожидали эквивалентные объекты. Передали:\n%s\nОжидали:\n%s")
s:set("assertion.equals.negative", "Ожидали не эквивалентные объекты. Передали:\n%s\nНе ожидали:\n%s")

s:set("assertion.unique.positive", "Ожидали, что объект будет уникальным:\n%s")
s:set("assertion.unique.negative", "Ожидали, что объект не будет уникальным:\n%s")

s:set("assertion.error.positive", "Ожидали ошибку.")
s:set("assertion.error.negative", "Не ожидали ошибку.\n%s")

s:set("assertion.truthy.positive", "Ожидали true, но значние оказалось:\n%s")
s:set("assertion.truthy.negative", "Ожидали не true, но значние оказалось:\n%s")

s:set("assertion.falsy.positive", "Ожидали false, но значние оказалось:\n%s")
s:set("assertion.falsy.negative", "Ожидали не false, но значние оказалось:\n%s")

---- definitions following are not used within the 'say' namespace but are defined as globals
failure_messages = {
  "У тебя %d просратых тестов",
  "Твои тесты поломаны",
  "Твой код говеный - пойди напейся!"
}

success_messages = {
  "Поехали!",
  "Жизнь - хороша!",
  "Ффух в этот раз пронесло!",
  "Ура!"
}

