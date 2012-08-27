s:set_namespace("ar")

-- "Pending: test.lua @ 12 \n description
s:set("output.pending", "عالِق")
s:set("output.failure", "فَشَل")
s:set("output.failure", "نَجاح")

s:set("output.pending_plural", "عالِق")
s:set("output.failure_plural", "إخْفاقات")
s:set("output.success_plural", "نَجاحات")

s:set("output.pending_zero", "عالِق")
s:set("output.failure_zero", "إخْفاقات")
s:set("output.success_zero", "نَجاحات")

s:set("output.pending_single", "عالِق")
s:set("output.failure_single", "فَشَل")
s:set("output.success_single", "نَجاح")

s:set("output.seconds", "ثَوانٍ")

s:set("assertion.same.positive", "تُوُقِّعَ تَماثُلُ الكائِنات. تَمَّ إدخال:\n %s. بَينَما كانَ مِن المُتَوقَّع:\n %s.")
s:set("assertion.same.negative", "تُوُقِّعَ إختِلافُ الكائِنات. تَمَّ إدخال:\n %s. بَينَما كانَ مِن غَيرِ المُتَوقَّع:\n %s.")

s:set("assertion.equals.positive", "تُوُقِّعَ أن تَتَساوىْ الكائِنات. تمَّ إِدخال:\n %s. بَينَما كانَ من المُتَوقَّع:\n %s.")
s:set("assertion.equals.negative", "تُوُقِّعَ ألّا تَتَساوىْ الكائِنات. تمَّ إِدخال:\n %s. بَينَما كانَ مِن غير المُتًوقَّع:\n %s.")

s:set("assertion.unique.positive", "تُوُقِّعَ أَنْ يَكونَ الكائِنٌ فَريد: \n%s")
s:set("assertion.unique.negative", "تُوُقِّعَ أنْ يَكونَ الكائِنٌ غَيرَ فَريد: \n%s")

s:set("assertion.error.positive", "تُوُقِّعَ إصدارُ خطأْ.")
s:set("assertion.error.negative", "تُوُقِّعَ عدم إصدارِ خطأ.")

s:set("assertion.truthy.positive", "تُوُقِّعَت قيمةٌ صَحيحة، بينما كانت: \n%s")
s:set("assertion.truthy.negative", "تُوُقِّعَت قيمةٌ غيرُ صَحيحة، بينما كانت: \n%s")

s:set("assertion.falsy.positive", "تُوُقِّعَت قيمةٌ خاطِئة، بَينَما كانت: \n%s")
s:set("assertion.falsy.negative", "تُوُقِّعَت قيمةٌ غيرُ خاطِئة، بَينَما كانت: \n%s")

failure_messages = { 
    "فَشِلَت %d مِنْ الإِختِبارات",
    "فَشِلَت إخْتِباراتُك",
    "برمجيَّتُكَ ضَعيْفة، أنْصَحُكَ بالتَّقاعُد",
    "تقع برمجيَّتُكَ في مَنطِقَةِ الخَطَر", 
    "أقترِحُ ألّا تَتَقَدَّم بالإختِبار، علَّ يبْقى الطابِقُ مَستوراَ", 
    "جَدَّتي، فِي أَثْناءِ نَومِها، تَكتبُ بَرمَجياتٍ أفْضلُ مِن هذه", 
    "يَوَدُّ ليْ مُساعَدَتُكْ، لَكِنّْ..." 
}

success_messages = {
    "رائِع! تَمَّ إجْتِيازُ جَميعُ الإختِباراتِ بِنَجاحٍ",
    "قُل ما شِئت، لا أكتَرِث: busted شَهِدَ لي!",
    "حَقَّ عَليْكَ الإفتِخار",
    "نَجاحٌ مُبْهِر!",
    "عَليكَ بالإحتِفال؛ نَجَحَت جَميعُ التَجارُب"  
}
