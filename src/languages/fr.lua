s:set_namespace("fr")

-- "Pending: test.lua @ 12 \n description
s:set("output.pending", "En attente")
s:set("output.failure", "Echec")
s:set("output.success", "Reussite")

s:set("output.pending_plural", "en attente")
s:set("output.failure_plural", "echecs")
s:set("output.success_plural", "reussites")

s:set("output.pending_zero", "en attente")
s:set("output.failure_zero", "echec")
s:set("output.success_zero", "reussite")

s:set("output.pending_single", "en attente")
s:set("output.failure_single", "echec")
s:set("output.success_single", "reussite")

s:set("output.seconds", "secondes")

s:set("assertion.same.positive", "Objets supposes de meme nature attendus. Argument passe:\n%s\Attendu:\n%s")
s:set("assertion.same.negative", "Objets supposes de natures differentes attendus. Argument passe:\n%s\nNon attendu:\n%s")

s:set("assertion.equals.positive", "Objets supposes etre de valeur egale attendus. Argument passe:\n%s\nAttendu:\n%s")
s:set("assertion.equals.negative", "Objets supposes etre de valeurs differentes attendu. Argument passe:\n%s\nNon attendu:\n%s")

s:set("assertion.unique.positive", "Objet suppose etre unique attendu:\n%s")
s:set("assertion.unique.negative", "Objet suppose ne pas etre unique attendu:\n%s")

s:set("assertion.error.positive", "Erreur supposee etre generee.")
s:set("assertion.error.negative", "Erreur non supposee etre generee.\n%s")

s:set("assertion.truthy.positive", "Assertion supposee etre vraie mais de valeur:\n%s")
s:set("assertion.truthy.negative", "Assertion supposee etre fausse mais de valeur:\n%s")

s:set("assertion.falsy.positive", "Assertion supposee etre fausse mais de valeur:\n%s")
s:set("assertion.falsy.negative", "Assertion supposee etre vraie mais de valeur:\n%s")

failure_messages = {
  "Vous avez %d test(s) qui a/ont echoue(s)",
  "Vos tests ont echoue.",
  "Votre code source est mauvais et vous devrez vous sentir mal",
  "Vous avez un code source de Destruction Massive",
  "Jeu plutot etrange game. Le seul moyen de gagner est de ne pas l'essayer",
  "Meme ma grand-mere ecrivait de meilleurs tests sur un PIII x86",
  "A chaque erreur, prenez une biere",
  "Ca craint, mon pote"
}

success_messages = {
  "Oh yeah, tests reussis",
  "Pas grave, y'a eu du succes",
  "C'est du bon, mon pote. Que du bon!",
  "Reussi, haut la main!",
  "Test reussi. Un de plus. Offre toi une biere, sur mon compte!",
}
