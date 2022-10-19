local s = require('say')

s:set_namespace('id')

-- 'Pending: test.lua @ 12 \n description
s:set('output.pending', 'Tertunda')
s:set('output.failure', 'Gagal')
s:set('output.error', 'Salah')
s:set('output.success', 'Berhasil')

s:set('output.pending_plural', 'tertunda')
s:set('output.failure_plural', 'kegagalan')
s:set('output.error_plural', 'kesalahan')
s:set('output.success_plural', 'berhasil')

s:set('output.pending_zero', 'tertunda')
s:set('output.failure_zero', 'kegagalan')
s:set('output.error_zero', 'kesalahan')
s:set('output.success_zero', 'berhasil')

s:set('output.pending_single', 'tertunda')
s:set('output.failure_single', 'gagal')
s:set('output.error_single', 'salah')
s:set('output.success_single', 'berhasil')

s:set('output.seconds', 'detik')

s:set('output.no_test_files_match', 'Tidak ada file uji coba yang cocok dengan pola (lua): %s')
s:set('output.file_not_found', 'Tidak dapat menemukan file ataupun direktori: %s')

-- definitions following are not used within the 'say' namespace
return {
  failure_messages = {
    'Anda memiliki %d spesifikasi yang rusak',
    'Spesifikasi anda rusak',
    'Kode anda buruk, sebaiknya anda merasa buruk',
    'Kode anda ada di zona berbahaya',
    'Percobaan yang aneh. Satu-satunya cara untuk menang bukanlah dengan menguji',
    'Nenek saya menulis spesifikasi lebih baik dalam 3 86',
    'Setiap saat ada kegagalan, minum bajigur lagi',
    'Merasa buruklah bung'
  },
  success_messages = {
    'Aww yeah, spesifikasi dipenuhi',
    'Tidak masalah, memenuhi spesifikasi',
    'Spertinya baik, bung',
    'Sukses besar',
    'Uji coba berhasil, minum bajigur lagi',
  }
}
