local s = require('say')

s:set_namespace("ua")

-- "Pending: test.lua @ 12 \n description
s:set("output.pending", "Очікує")
s:set("output.failure", "Зламався")
s:set("output.success", "Пройшов")

s:set("output.pending_plural", "очікують")
s:set("output.failure_plural", "зламались")
s:set("output.success_plural", "пройшли")

s:set("output.pending_zero", "очікуючих")
s:set("output.failure_zero", "зламаних")
s:set("output.success_zero", "пройдених")

s:set("output.pending_single", "очікує")
s:set("output.failure_single", "зламався")
s:set("output.success_single", "пройшов")

s:set("output.seconds", "секунд")

s:set("assertion.same.positive", "Очікували однакові обєкти. Передали:\n%s\nОчікували:\n%s")
s:set("assertion.same.negative", "Очікували різні обєкти. Передали:\n%s\nНе очікували:\n%s")

s:set("assertion.equals.positive", "Очікували еквівалентні обєкти. Передали:\n%s\nОчікували:\n%s")
s:set("assertion.equals.negative", "Очікували не еквівалентні обєкти. Передали:\n%s\nНе очікували:\n%s")

s:set("assertion.unique.positive", "Очікували, що обєкт буде унікальним:\n%s")
s:set("assertion.unique.negative", "Очікували, що обєкт не буде унікальним:\n%s")

s:set("assertion.error.positive", "Очікували помилку.")
s:set("assertion.error.negative", "Не очікували помилку.\n%s")

s:set("assertion.truthy.positive", "Очікували true, проте значння виявилось:\n%s")
s:set("assertion.truthy.negative", "Очікували не true, проте значння виявилось:\n%s")

s:set("assertion.falsy.positive", "Очікували false, проте значння виявилось:\n%s")
s:set("assertion.falsy.negative", "Очікували не false, проте значння виявилось:\n%s")

---- definitions following are not used within the 'say' namespace but are defined as globals
failure_messages = {
  "Ти зрадив %d тестів!",
  "Ой йо..",
  "Вороги поламали наші тести!"
}

success_messages = {
  "Слава Україні! Героям Слава!",
  "Тестування успішно пройдено!",
  "Всі баги знищено!"
}

