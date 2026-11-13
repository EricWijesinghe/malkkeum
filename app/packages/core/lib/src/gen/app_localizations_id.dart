// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class TId extends T {
  TId([String locale = 'id']) : super(locale);

  @override
  String get addressSearch => 'Cari alamat';

  @override
  String get addressSearchHint =>
      'Cari dengan nama jalan, gedung, atau nomor lot';

  @override
  String get addressSearchButton => 'Cari';

  @override
  String get addressSearchMinChars => 'Masukkan minimal 2 karakter';

  @override
  String get addressNoResults => 'Tidak ada hasil. Coba kata lain.';

  @override
  String get addressManualEntry => 'Isi manual';

  @override
  String get cardRegisterTitle => 'Daftar kartu';

  @override
  String get cIntJuso => 'Pencarian alamat (juso.go.kr)';

  @override
  String get aiLabel => 'Asisten AI';

  @override
  String get aiBadge => 'AI';

  @override
  String get aiCardHint =>
      'Menjawab chat pelanggan secara otomatis. Setiap pesan dikenai biaya API.';

  @override
  String get aiModeOffline => 'Jawab hanya saat staf tidak ada';

  @override
  String get aiModeAlways => 'AI selalu menjawab lebih dulu';

  @override
  String get aiPause => 'Jeda AI';

  @override
  String get aiResume => 'Lanjutkan AI';

  @override
  String get aiPausedNote => 'AI dijeda untuk chat ini';

  @override
  String aiUsageMonth(String count) {
    return 'Panggilan AI bulan ini: $count';
  }

  @override
  String get aiNotConfigured => 'AI pendamping mati';

  @override
  String get aiCapThreadLabel => 'Batas balasan per chat per jam';

  @override
  String get aiCapMemberLabel => 'Batas balasan per pelanggan per hari';

  @override
  String get aiCapDailyLabel => 'Batas balasan per hari, semua chat';

  @override
  String get aiCapHint => 'Hanya angka. Kosongkan untuk nilai default.';

  @override
  String get apSocialOr => 'atau';

  @override
  String get apSocialSignIn => 'Masuk cepat';

  @override
  String get apLoginKakao => 'Lanjut dengan Kakao';

  @override
  String get apLoginNaver => 'Lanjut dengan Naver';

  @override
  String get apLoginGoogle => 'Lanjut dengan Google';

  @override
  String get apLoginApple => 'Lanjut dengan Apple';

  @override
  String get apDevSocialNote =>
      'Mode pengembangan: masuk dengan akun uji, bukan akun sosial asli.';

  @override
  String get apSocialFailed => 'Masuk cepat gagal. Silakan coba lagi.';

  @override
  String get apProviderNotConfigured => 'Metode masuk ini belum tersedia';

  @override
  String get apPhoneTaken => 'Nomor ini sudah terhubung dengan akun lain';

  @override
  String get apPhoneAttachTitle => 'Verifikasi nomor ponsel Anda';

  @override
  String get apPhoneAttachBody =>
      'Nomor ini dipakai untuk pemesanan dan komunikasi dengan mitra. Cukup diverifikasi sekali.';

  @override
  String get apPayAllTitle => 'Pilih metode pembayaran';

  @override
  String get apPaySavedTitle => 'Metode tersimpan';

  @override
  String get apPayMoreTitle => 'Semua metode pembayaran';

  @override
  String get apPayBillingHint =>
      'Simpan sekali, bayar dengan satu ketukan berikutnya';

  @override
  String get apPayCheckoutHint => 'Selesaikan di jendela pembayaran';

  @override
  String get apPayRegistering => 'Mendaftarkan…';

  @override
  String get apPayManageHint =>
      'Bayar dengan satu ketukan memakai metode tersimpan. Tambahkan dompet digital di sini.';

  @override
  String get apMethodCard => 'Kartu kredit & debit';

  @override
  String get apMethodKakao => 'KakaoPay';

  @override
  String get apMethodNaver => 'NaverPay';

  @override
  String get apMethodToss => 'TossPay';

  @override
  String get apMethodPayco => 'PAYCO';

  @override
  String get apMethodSamsung => 'Samsung Pay';

  @override
  String get apMethodApple => 'Apple Pay';

  @override
  String get apMethodTransfer => 'Transfer bank';

  @override
  String get apMethodVirtual => 'Rekening virtual';

  @override
  String get apMethodPhone => 'Tagihan ponsel';

  @override
  String get apMethodUnknown => 'Lainnya';

  @override
  String get apVaTitle => 'Rekening setoran Anda sudah siap';

  @override
  String get apVaWaiting => 'Menunggu setoran';

  @override
  String get apVaBody =>
      'Pemesanan dikonfirmasi setelah setoran diterima. Kami memeriksanya secara otomatis.';

  @override
  String get apVaBank => 'Bank';

  @override
  String get apVaAccount => 'Nomor rekening';

  @override
  String get apVaHolder => 'Atas nama';

  @override
  String get apVaAmount => 'Jumlah';

  @override
  String apVaDue(String due) {
    return 'Transfer sebelum $due';
  }

  @override
  String get apVaCopy => 'Salin';

  @override
  String get apVaCopied => 'Nomor rekening disalin';

  @override
  String get apVaBannerTitle => 'Ada pemesanan yang menunggu setoran';

  @override
  String apVaBannerBody(String amount, String due) {
    return '$amount · sebelum $due';
  }

  @override
  String get apVaBannerAction => 'Lihat rekening';

  @override
  String get apPgTitle => 'Jendela pembayaran';

  @override
  String get apPgDevNote =>
      'Simulasi pembayaran khusus pengembangan. Tidak ada tagihan sungguhan.';

  @override
  String apPgPay(String amount) {
    return 'Bayar $amount';
  }

  @override
  String get apPgIssue => 'Dapatkan nomor rekening';

  @override
  String get apPgCancel => 'Batalkan pembayaran';

  @override
  String get apErrSlotFullRefunded =>
      'Jadwal itu baru saja penuh, jadi pembayaran Anda dibatalkan otomatis';

  @override
  String get apErrCheckoutExpired =>
      'Waktu pembayaran habis. Silakan coba lagi.';

  @override
  String get apIdentityTitle => 'Verifikasi identitas (PASS)';

  @override
  String get apIdentityBody =>
      'Memastikan identitas Anda lewat operator seluler. Dipakai untuk transaksi dan pencairan yang aman.';

  @override
  String get apIdentityAction => 'Verifikasi identitas';

  @override
  String get apIdentityDone => 'Identitas berhasil diverifikasi';

  @override
  String get apIdentityVerified => 'Terverifikasi';

  @override
  String get apIdentityUnverified => 'Belum diverifikasi';

  @override
  String get apIdentityDevTitle => 'Verifikasi identitas uji';

  @override
  String get apIdentityDevBody =>
      'Di mode pengembangan, verifikasi otomatis lolos tanpa pemeriksaan sungguhan.';

  @override
  String get apIdentityDevPass => 'Lolos';

  @override
  String get apPayManageTitle => 'Daftar dompet digital';

  @override
  String get bizInfoTitle => 'Informasi usaha';

  @override
  String get bizInfoVerify => 'Verifikasi pendaftaran usaha';

  @override
  String get cSetupHostingProvider => 'Penyedia hosting';

  @override
  String get cTitle => 'Konsol operasional';

  @override
  String get cEmail => 'Email';

  @override
  String get cPassword => 'Kata sandi';

  @override
  String get cLogin => 'Masuk';

  @override
  String get cLoginFailed => 'Email atau kata sandi salah';

  @override
  String get cDashboard => 'Dasbor';

  @override
  String get cBookings => 'Pemesanan';

  @override
  String get cQuoteDesk => 'Meja penawaran';

  @override
  String get cInbox => 'Kotak masuk';

  @override
  String get cCatalog => 'Katalog & harga';

  @override
  String get cMarketing => 'Kupon & konten';

  @override
  String get cPartners => 'Mitra';

  @override
  String get cSettlements => 'Pencairan';

  @override
  String get cCustomers => 'Pelanggan';

  @override
  String get cStaff => 'Staf';

  @override
  String get cSearchCommand => 'Cari atau pindah';

  @override
  String get cPaletteHint => 'Ketik nama menu atau nomor pemesanan';

  @override
  String get cTodayJobs => 'Pekerjaan hari ini';

  @override
  String get cOpenQuotes => 'Penawaran menunggu';

  @override
  String get cUnassigned => 'Belum ditugaskan';

  @override
  String get cUnreadThreads => 'Chat belum dibaca';

  @override
  String get cRevenue30 => 'Pendapatan 30 hari';

  @override
  String get cBookings30 => 'Pemesanan 30 hari';

  @override
  String get cByService => 'Pemesanan per layanan (30 hari)';

  @override
  String get cAllStatus => 'Semua status';

  @override
  String get cAllServices => 'Semua layanan';

  @override
  String get cSearch => 'Cari (nomor, telepon, nama, alamat)';

  @override
  String get cNoResults => 'Tidak ada hasil';

  @override
  String get cNumber => 'Nomor';

  @override
  String get cVisit => 'Kunjungan';

  @override
  String get cService => 'Layanan';

  @override
  String get cStatus => 'Kondisi';

  @override
  String get cTeam => 'Tim';

  @override
  String get cAmount => 'Jumlah';

  @override
  String get cCustomer => 'Pelanggan';

  @override
  String get cPayments => 'Pembayaran';

  @override
  String get cChangeStatus => 'Ubah status';

  @override
  String get cTeamName => 'Tim yang ditugaskan';

  @override
  String get cAssign => 'Tugaskan tim';

  @override
  String get cMarkDone => 'Tandai selesai';

  @override
  String get cConfirm => 'Tandai terkonfirmasi';

  @override
  String get cCancelRefund => 'Batalkan & kembalikan dana';

  @override
  String get cRefundAmount => 'Jumlah pengembalian (kosongkan = penuh)';

  @override
  String get cDone => 'Selesai';

  @override
  String get cAnswers => 'Jawaban pelanggan';

  @override
  String get cEstimateCalc => 'Estimasi otomatis';

  @override
  String get cBase => 'Dasar';

  @override
  String get cExtras => 'Tambahan';

  @override
  String get cSurcharge => 'Biaya tambahan';

  @override
  String get cBeforeVat => 'Sebelum PPN';

  @override
  String get cProQuotes => 'Penawaran mitra';

  @override
  String get cNoProQuotes => 'Belum ada penawaran masuk';

  @override
  String get cFinalPrice => 'Harga akhir untuk pelanggan';

  @override
  String get cQuoteNote => 'Catatan untuk pelanggan';

  @override
  String get cSendQuote => 'Kirim penawaran ke pelanggan';

  @override
  String get cQuoteSent => 'Penawaran terkirim';

  @override
  String get cCustomerChats => 'Pelanggan';

  @override
  String get cPartnerChats => 'Mitra';

  @override
  String get cSelectBooking => 'Pilih pemesanan';

  @override
  String get cRefunded => 'Dikembalikan';

  @override
  String get cPartRefunded => 'Dikembalikan sebagian';

  @override
  String get cFailed => 'Gagal';

  @override
  String get cSelectThread => 'Pilih percakapan';

  @override
  String get cReplyHint => 'Ketik balasan · Ctrl+Enter untuk kirim';

  @override
  String get cOpenBooking => 'Buka pemesanan';

  @override
  String get cShortcuts => 'J/K pindah · Ctrl+K perintah';

  @override
  String get cPricing => 'Harga';

  @override
  String get cMinutes => 'Durasi (menit)';

  @override
  String get cActive => 'Aktif';

  @override
  String get cSaved => 'Tersimpan';

  @override
  String get cSlotCapacity => 'Kapasitas per jam kedatangan';

  @override
  String get cUnlimited => 'Tidak terbatas';

  @override
  String get cFormula => 'Rumus penawaran';

  @override
  String get cTabCancelPolicy => 'Kebijakan pembatalan';

  @override
  String get cPolicyDefaultBanner =>
      'Ini pengaturan bawaan. Periksa dan simpan untuk mengonfirmasi.';

  @override
  String get cPolicyDaysBefore => 'Hari sebelum kunjungan (mulai)';

  @override
  String get cPolicyPercent =>
      'Biaya % (kosong = tidak bisa dibatalkan di aplikasi)';

  @override
  String get cPolicyMinFee => 'Biaya minimum (KRW)';

  @override
  String get cPolicyReschedule =>
      'Boleh ubah jadwal (dari berapa hari sebelum kunjungan)';

  @override
  String get cPolicyHint =>
      'Langsung berlaku di layar pembatalan aplikasi pelanggan. Ketentuan diperbarui di build legal berikutnya.';

  @override
  String get f_base_studio => 'Dasar: studio';

  @override
  String get f_base_one_and_half => 'Dasar: 1,5 kamar';

  @override
  String get f_base_two_rooms => 'Dasar: 2 kamar';

  @override
  String get f_base_three_rooms => 'Dasar: 3 kamar';

  @override
  String get f_base_four_plus => 'Dasar: 4+ kamar';

  @override
  String get f_per_extra_bathroom => 'Per kamar mandi tambahan';

  @override
  String get f_per_balcony => 'Per balkon';

  @override
  String get f_duplex => 'Dupleks';

  @override
  String get f_no_elevator_high_floor => 'Tanpa lift & lantai 3+';

  @override
  String get cIssueCoupon => 'Terbitkan kupon';

  @override
  String get cCouponName => 'Nama kupon';

  @override
  String get cCouponPhones => 'Nomor telepon (satu per baris)';

  @override
  String get cAllCustomers => 'Untuk semua pelanggan';

  @override
  String cIssued(String n) {
    return '$n kupon diterbitkan';
  }

  @override
  String get cContent => 'Konten';

  @override
  String get cKind_notice => 'Pengumuman';

  @override
  String get cKind_tip => 'Tips';

  @override
  String get cKind_faq => 'FAQ';

  @override
  String get cKind_banner => 'Spanduk';

  @override
  String get cKind_legal => 'Ketentuan';

  @override
  String get cNewContent => 'Konten baru';

  @override
  String get cTitleField => 'Judul';

  @override
  String get cBodyField => 'Isi';

  @override
  String get cSlug => 'Slug (ketentuan: privacy / terms)';

  @override
  String get cVerify => 'Setujui';

  @override
  String get cSuspend => 'Tangguhkan';

  @override
  String get cPro_pending => 'Menunggu';

  @override
  String get cPro_verified => 'Aktif';

  @override
  String get cPro_suspended => 'Ditangguhkan';

  @override
  String get cCompleted => 'Selesai';

  @override
  String get cCancelledN => 'Dibatalkan';

  @override
  String get cRating => 'Penilaian';

  @override
  String get cFeeRate => 'Biaya %';

  @override
  String get cRunPayouts => 'Jalankan pencairan';

  @override
  String get cPayoutDate => 'Cairkan hingga tanggal';

  @override
  String cPayoutDone(String n) {
    return 'Pencairan untuk $n mitra sudah diproses';
  }

  @override
  String get cHold => 'Tahan';

  @override
  String get cRelease => 'Lepaskan tahanan';

  @override
  String get cNet => 'Bersih';

  @override
  String get cAddStaff => 'Tambah staf';

  @override
  String get cRoleAdmin => 'Pengelola';

  @override
  String get cRoleConsultant => 'Konsultan';

  @override
  String get cDeactivate => 'Nonaktifkan';

  @override
  String get cActivate => 'Aktifkan';

  @override
  String get cPasswordRule => 'Minimal 12 karakter';

  @override
  String get cAdminOnly => 'Hanya admin';

  @override
  String cBookingsCount(String n) {
    return '$n pemesanan';
  }

  @override
  String get cJoined => 'Bergabung';

  @override
  String get cNewBooking => 'Pemesanan baru';

  @override
  String get cNewMessage => 'Pesan baru';

  @override
  String get cConfirmAsk => 'Yakin ingin melanjutkan?';

  @override
  String get cServerTitle => 'Masukkan alamat server';

  @override
  String get cServerBody =>
      'Masukkan alamat server yang diawali https:// dari catatan penyiapan. Cukup diisi sekali.';

  @override
  String get cServerSave => 'Simpan dan lanjutkan';

  @override
  String get cServerInvalid =>
      'Alamat tidak valid. Masukkan alamat server yang diawali https://.';

  @override
  String get cServerChange => 'Ubah alamat server';

  @override
  String get ok => 'Oke';

  @override
  String get cancel => 'Batal';

  @override
  String get next => 'Lanjut';

  @override
  String get close => 'Tutup';

  @override
  String get save => 'Simpan';

  @override
  String get delete => 'Hapus';

  @override
  String get edit => 'Ubah';

  @override
  String get change => 'Ganti';

  @override
  String get retry => 'Coba lagi';

  @override
  String get yes => 'Ya';

  @override
  String get no => 'Tidak';

  @override
  String get required => 'Wajib';

  @override
  String get viewAll => 'Lihat semua';

  @override
  String get today => 'Hari ini';

  @override
  String get errorGeneric => 'Terjadi kesalahan. Silakan coba lagi nanti.';

  @override
  String get errorNetwork => 'Periksa koneksi internet Anda';

  @override
  String get err_invalid_phone => 'Periksa nomor ponsel Anda';

  @override
  String get err_otp_invalid => 'Kode tidak sesuai';

  @override
  String get err_otp_expired => 'Kode sudah kedaluwarsa. Minta kode baru.';

  @override
  String get err_rate_limited => 'Terlalu banyak percobaan. Coba lagi nanti.';

  @override
  String get err_studio_too_large =>
      'Pembersihan studio hanya untuk rumah hingga 10 pyeong';

  @override
  String get err_date_out_of_range =>
      'Pilih tanggal mulai besok hingga 60 hari ke depan';

  @override
  String get err_slot_full => 'Jadwal itu baru saja penuh. Pilih waktu lain.';

  @override
  String get err_coupon_expired => 'Kupon ini sudah kedaluwarsa';

  @override
  String get err_coupon_used => 'Kupon ini sudah pernah digunakan';

  @override
  String get err_coupon_wrong_service =>
      'Kupon ini tidak berlaku untuk layanan ini';

  @override
  String get err_payment_failed => 'Pembayaran ditolak. Coba metode lain.';

  @override
  String get err_payment_method_required => 'Pilih metode pembayaran';

  @override
  String get err_cancellation_window_closed =>
      'Pemesanan ini tidak bisa dibatalkan lagi lewat aplikasi. Silakan hubungi tim kami';

  @override
  String get err_address_required => 'Tambahkan alamat kunjungan';

  @override
  String get err_already_taken => 'Mitra lain sudah menerimanya lebih dulu';

  @override
  String get err_invalid_address => 'Isi semua kolom alamat';

  @override
  String get tabHome => 'Beranda';

  @override
  String get tabBookings => 'Pesananku';

  @override
  String get tabChat => 'Obrolan';

  @override
  String get tabMore => 'Lainnya';

  @override
  String get introTitle => 'Pembersihan profesional,\ndipesan dalam semenit';

  @override
  String get introBody =>
      'Harga transparan · Tim terverifikasi · Progres langsung';

  @override
  String get introStart => 'Lanjut dengan nomor ponsel';

  @override
  String get loginPhoneTitle => 'Berapa nomor ponsel Anda?';

  @override
  String get loginPhoneHint => '010-0000-0000';

  @override
  String get loginSendCode => 'Kirim kode';

  @override
  String get loginCodeTitle => 'Masukkan kode 6 digit';

  @override
  String loginCodeSentTo(String phone) {
    return 'Terkirim ke $phone';
  }

  @override
  String get loginResend => 'Kirim ulang';

  @override
  String get loginVerify => 'Verifikasi';

  @override
  String get loginTerms =>
      'Dengan melanjutkan, Anda menyetujui Syarat Layanan dan Kebijakan Privasi';

  @override
  String get profileTitle => 'Siapa nama Anda?';

  @override
  String get profileNameHint => 'Nama';

  @override
  String get profileDone => 'Mulai';

  @override
  String get welcomeToast => '2 kupon selamat datang sudah ada di dompet Anda';

  @override
  String get svc_studio => 'Pembersihan studio';

  @override
  String get svc_kitchen => 'Pembersihan dapur';

  @override
  String get svc_bathroom => 'Pembersihan kamar mandi';

  @override
  String get svc_mattress => 'Pembersihan kasur';

  @override
  String get svc_aircon => 'Pembersihan AC';

  @override
  String get svc_sofa => 'Pembersihan sofa';

  @override
  String get svc_move_out => 'Pembersihan pindah keluar';

  @override
  String get svc_move_in => 'Pembersihan pindah masuk';

  @override
  String get svcShort_studio => 'Studio';

  @override
  String get svcShort_kitchen => 'Dapur';

  @override
  String get svcShort_bathroom => 'Kamar mandi';

  @override
  String get svcShort_mattress => 'Kasur';

  @override
  String get svcShort_aircon => 'AC';

  @override
  String get svcShort_sofa => 'Sofa';

  @override
  String get svcShort_move_out => 'Pindah keluar';

  @override
  String get svcShort_move_in => 'Pindah masuk';

  @override
  String get svcDesc_studio =>
      'Pembersihan 2 jam menyeluruh untuk studio hingga 10 pyeong: satu kamar dan satu kamar mandi.';

  @override
  String get svcDesc_kitchen =>
      'Pembersihan dapur terfokus: bak cuci, kompor, bagian luar tudung, dan meja.';

  @override
  String get svcDesc_bathroom =>
      'Rak, keran, wastafel, dan toilet dibersihkan bagian dalam dan luar, lalu lantai dikeringkan.';

  @override
  String get svcDesc_mattress =>
      'Peralatan profesional menyedot debu, tungau, dan noda, lalu disterilkan dengan uap.';

  @override
  String get svcDesc_aircon =>
      'Dibongkar, lalu koil, kipas, dan filter dicuci tekanan tinggi dan disterilkan.';

  @override
  String get svcDesc_sofa =>
      'Pembersih sesuai bahan menguraikan kotoran, lalu diangkat dengan metode ekstraksi basah.';

  @override
  String get svcDesc_move_out =>
      'Sebelum pindah keluar, tim profesional datang membawa peralatan dan membersihkan rumah kosong.';

  @override
  String get svcDesc_move_in =>
      'Sebelum pindah masuk, tim profesional datang membawa peralatan dan membersihkan rumah baru.';

  @override
  String get svcNotes_bathroom =>
      'Saluran atau toilet yang tersumbat dapat membatasi layanan\nPembersihan yang memerlukan bahan kimia khusus, langit-langit, atau ventilasi tidak termasuk\nJamur lama dan kotoran membandel mungkin tidak hilang sepenuhnya';

  @override
  String get svcNotes_mattress =>
      'Harga sama dari ukuran single hingga king\nKering sempurna dalam 4–6 jam\nKerusakan per pegas atau kasur melesak tidak dapat diperbaiki';

  @override
  String get svcNotes_aircon =>
      'Unit berusia lebih dari 10 tahun mungkin tidak aman untuk dibongkar\nUnit outdoor tidak termasuk\nKami memeriksa fungsi sebelum dan sesudah pembersihan';

  @override
  String get svcNotes_sofa =>
      'Sofa kulit dibersihkan lalu dilapisi pelembap\nNoda lama atau luntur warna mungkin tidak hilang sepenuhnya\nKering sempurna dalam 4–6 jam';

  @override
  String get unitTitle_bathroom => 'Jumlah kamar mandi';

  @override
  String get unitTitle_mattress => 'Jumlah kasur';

  @override
  String get unitTitle_aircon => 'Jenis AC';

  @override
  String get unitTitle_sofa => 'Ukuran sofa';

  @override
  String unit_count(String n) {
    return '$n unit';
  }

  @override
  String get unit_wall => 'Dinding 1 unit';

  @override
  String get unit_stand => 'Berdiri 1 unit';

  @override
  String get unit_two_in_one => '2in1 (berdiri + dinding)';

  @override
  String get unit_ceiling => 'Kaset langit-langit 1 unit';

  @override
  String get unit_seat_1_2 => '1–2 kursi';

  @override
  String get unit_seat_3 => '3 kursi';

  @override
  String get unit_seat_4_plus => '4+ kursi';

  @override
  String get unit_l_shape => 'Bentuk L / couch';

  @override
  String durH(String h) {
    return '$h jam';
  }

  @override
  String durHM(String h, String m) {
    return '$h jam $m menit';
  }

  @override
  String durM(String m) {
    return '$m menit';
  }

  @override
  String about(String value) {
    return 'sekitar $value';
  }

  @override
  String fromPrice(String price) {
    return 'mulai $price';
  }

  @override
  String get quoteBadge => 'Penawaran';

  @override
  String get status0 => 'Konsultasi';

  @override
  String get status1 => 'Terkonfirmasi';

  @override
  String get status2 => 'Tim ditugaskan';

  @override
  String get status3 => 'Selesai';

  @override
  String get statusCancelled => 'Dibatalkan';

  @override
  String homeGreeting(String name) {
    return 'Halo, $name\nMau bersihkan bagian mana hari ini?';
  }

  @override
  String get homeGreetingAnon => 'Mau bersihkan bagian mana\nhari ini?';

  @override
  String get homeUpcoming => 'Akan datang';

  @override
  String dDay(String days) {
    return 'H-$days';
  }

  @override
  String get homeServices => 'Layanan apa yang Anda butuhkan?';

  @override
  String get homeAddAddress =>
      'Tambahkan alamat untuk melihat layanan dan harga yang tersedia';

  @override
  String get homeAddAddressCta => 'Tambah alamat';

  @override
  String homeRebook(String service) {
    return 'Pesan $service lagi';
  }

  @override
  String get homeRebookBody =>
      'Pakai pilihan yang sama seperti terakhir, cukup dua ketukan';

  @override
  String get homeNotices => 'Info terbaru';

  @override
  String get trustVat => 'PPN sudah termasuk\nHarga yang tertera sudah final';

  @override
  String get trustCancel => 'Pembatalan gratis\nhingga 2 hari sebelumnya';

  @override
  String get trustCard => 'Data kartu hanya disimpan\ndi penyedia pembayaran';

  @override
  String stepOf(String current, String total) {
    return '$current dari $total';
  }

  @override
  String get chooseDate => 'Pilih tanggal';

  @override
  String get notIncluded => 'Perlu diketahui';

  @override
  String studioBlockedTitle(String size) {
    return '$size pyeong terlalu besar untuk pembersihan studio';
  }

  @override
  String get studioBlockedBody =>
      'Tim konsultan kami akan merekomendasikan layanan yang sesuai untuk rumah Anda.';

  @override
  String get consultCta => 'Tanya tim kami';

  @override
  String get addressTitle => 'Ke mana kami harus datang?';

  @override
  String get addressAdd => 'Tambah alamat baru';

  @override
  String get addressLabel => 'Nama';

  @override
  String get addressLabelHint => 'mis. Rumah';

  @override
  String get addressDistrict => 'Kecamatan';

  @override
  String get addressRoad => 'Alamat jalan';

  @override
  String get addressDetail => 'Detail (unit / lantai)';

  @override
  String get addressSize => 'Luas rumah (pyeong)';

  @override
  String get addressSizeHelp => 'Luas bersih · 1 pyeong ≈ 3,3 m²';

  @override
  String get addressHome => 'Rumah';

  @override
  String get addressOffice => 'Kantor';

  @override
  String get addressEmpty => 'Belum ada alamat tersimpan';

  @override
  String get addressSaved => 'Alamat tersimpan';

  @override
  String pyeong(String n) {
    return '$n pyeong';
  }

  @override
  String get scheduleTitle => 'Kapan kami sebaiknya datang?';

  @override
  String get scheduleArrival => 'Waktu kedatangan';

  @override
  String get scheduleFull => 'Penuh';

  @override
  String scheduleWindow(String start, String end) {
    return 'Tiba pukul $start–$end';
  }

  @override
  String scheduleEnds(String duration, String time) {
    return '$duration · selesai sekitar pukul $time';
  }

  @override
  String get scheduleRange => 'Pesan mulai besok hingga 60 hari ke depan';

  @override
  String get morning => 'Pagi';

  @override
  String get afternoon => 'Siang';

  @override
  String get scheduleQuoteNote =>
      'Waktu kedatangan pasti akan kami konfirmasi lewat chat';

  @override
  String get goToPayment => 'Lanjut ke pembayaran';

  @override
  String get prepTitle => 'Mohon siapkan ini sebelum kunjungan';

  @override
  String get prepBody =>
      'Sebagian pekerjaan mungkin terbatas tanpa perlengkapan ini';

  @override
  String get prepAsk => 'Tidak bisa menyiapkannya? Beri tahu tim kami';

  @override
  String get tool_vacuum => 'Penyedot debu';

  @override
  String get tool_trash => 'Kantong sampah';

  @override
  String get tool_mop => 'Pel';

  @override
  String get tool_cloth => 'Kain lap';

  @override
  String get tool_gloves => 'Sarung tangan karet';

  @override
  String get tool_sponge => 'Spons gosok';

  @override
  String get tool_spray => 'Pembersih serbaguna';

  @override
  String get checkoutTitle => 'Pembayaran';

  @override
  String get coupon => 'Kupon';

  @override
  String get couponNone => 'Tidak dipakai';

  @override
  String couponAvailable(String count) {
    return '$count tersedia';
  }

  @override
  String get paymentMethod => 'Metode pembayaran';

  @override
  String get addPaymentMethod => 'Tambah metode pembayaran';

  @override
  String get methodCard => 'Kartu kredit / debit';

  @override
  String get methodKakao => 'KakaoPay';

  @override
  String get methodNaver => 'Naver Pay';

  @override
  String get methodToss => 'Toss Pay';

  @override
  String get methodRegistered => 'Ditambahkan';

  @override
  String get methodAdded => 'Metode pembayaran ditambahkan';

  @override
  String get listPrice => 'Layanan';

  @override
  String get discount => 'Diskon kupon';

  @override
  String get total => 'Total pembayaran';

  @override
  String get vatIncluded => 'PPN sudah termasuk';

  @override
  String payAmount(String amount) {
    return 'Bayar $amount';
  }

  @override
  String get needMethod => 'Tambahkan metode pembayaran terlebih dahulu';

  @override
  String freeCancelUntil(String date) {
    return 'Pembatalan gratis hingga $date';
  }

  @override
  String get doneTitle => 'Pemesanan berhasil!';

  @override
  String get doneBody =>
      'Kami akan memberi tahu Anda segera setelah tim ditugaskan';

  @override
  String get doneQuoteTitle => 'Permintaan konsultasi diterima';

  @override
  String get doneQuoteBody =>
      'Tim konsultan kami akan memeriksa dan mengirim penawaran final. Anda bisa melihatnya di tab Chat.';

  @override
  String get goHome => 'Ke beranda';

  @override
  String get viewBooking => 'Lihat pemesanan';

  @override
  String get bookingsTitle => 'Pemesanan';

  @override
  String get bookingsUpcoming => 'Akan datang';

  @override
  String get bookingsPast => 'Riwayat';

  @override
  String get bookingsEmpty => 'Belum ada pemesanan';

  @override
  String get bookingsEmptyBody =>
      'Kupon selamat datang menunggu untuk pemesanan pertama Anda';

  @override
  String get bookNow => 'Pesan pembersihan';

  @override
  String get detailTitle => 'Detail pemesanan';

  @override
  String get stepRequested => 'Permintaan diterima';

  @override
  String get stepConfirmed => 'Terkonfirmasi';

  @override
  String get stepAssigned => 'Tim ditugaskan';

  @override
  String get stepCompleted => 'Selesai';

  @override
  String teamVisiting(String team) {
    return '$team sedang menuju lokasi';
  }

  @override
  String get photosSoon => 'Foto sebelum & sesudah akan muncul di sini';

  @override
  String photoThumb(String n) {
    return 'Foto $n';
  }

  @override
  String get before => 'Sebelum';

  @override
  String get after => 'Sesudah';

  @override
  String get prepCheck => 'Daftar persiapan';

  @override
  String get prepAllSet => 'Semua siap';

  @override
  String get visitAddress => 'Alamat';

  @override
  String get paid => 'Dibayar';

  @override
  String get askTeam => 'Hubungi tim kami';

  @override
  String get cancelBooking => 'Batalkan pemesanan';

  @override
  String get cancelTitle => 'Batalkan pemesanan ini?';

  @override
  String get cancelFree =>
      'Jika dibatalkan sekarang, Anda mendapat pengembalian dana penuh dan kupon Anda dikembalikan.';

  @override
  String get cancelKeep => 'Tetap pesan';

  @override
  String cancelFeeNow(String fee, String refund) {
    return 'Jika dibatalkan sekarang, biaya $fee berlaku dan $refund akan dikembalikan.';
  }

  @override
  String cancelFeeAccept(String fee) {
    return 'Setujui biaya $fee dan batalkan';
  }

  @override
  String get cancelled => 'Pemesanan dibatalkan';

  @override
  String get reschedule => 'Ubah jadwal';

  @override
  String get rescheduled => 'Jadwal diubah';

  @override
  String get visitNotes => 'Catatan untuk tim';

  @override
  String get notesEntry => 'Cara masuk (kode pintu, dll.)';

  @override
  String get notesParking => 'Parkir';

  @override
  String get notesOther => 'Lainnya';

  @override
  String get notesSaved => 'Catatan tersimpan';

  @override
  String depositDue(String amount) {
    return 'Bayar deposit $amount untuk mengonfirmasi pemesanan';
  }

  @override
  String get payDeposit => 'Bayar deposit';

  @override
  String get waitingQuote => 'Tim kami sedang menyiapkan penawaran Anda';

  @override
  String get estimate => 'Estimasi';

  @override
  String get finalPrice => 'Penawaran final';

  @override
  String get deposit => 'Uang muka';

  @override
  String get balance => 'Sisa pembayaran';

  @override
  String balanceDue(String amount) {
    return 'Silakan bayar sisa pembayaran $amount';
  }

  @override
  String get payBalance => 'Bayar sisa pembayaran';

  @override
  String get reviewTitle => 'Bagaimana hasilnya?';

  @override
  String get reviewHint =>
      'Ceritakan apa yang sudah baik atau perlu diperbaiki';

  @override
  String ratingStars(String n) {
    return '$n bintang';
  }

  @override
  String get reviewSubmit => 'Kirim ulasan';

  @override
  String get reviewThanks => 'Terima kasih atas ulasan Anda';

  @override
  String get bookAgain => 'Pesan lagi';

  @override
  String get chatTitle => 'Obrolan';

  @override
  String get chatTeam => 'Tim konsultan';

  @override
  String get chatHours => 'Hari kerja 09.00–18.00';

  @override
  String get chatEmpty => 'Ada pertanyaan? Tanyakan kapan saja';

  @override
  String get chatNew => 'Chat baru';

  @override
  String get chatTopicTitle => 'Ada yang ingin Anda tanyakan?';

  @override
  String get topicOther => 'Pertanyaan lain';

  @override
  String get chatHint => 'Tulis pesan';

  @override
  String get chatSend => 'Kirim';

  @override
  String get chatPhoto => 'Kirim foto';

  @override
  String get chatTyping => 'Tim sedang mengetik…';

  @override
  String get quick_confirm => 'Saya ingin konfirmasi';

  @override
  String get quick_price => 'Tanya harga';

  @override
  String get quick_date => 'Ingin ubah tanggal';

  @override
  String get quick_parking => 'Apakah ada parkir?';

  @override
  String get quick_hello => 'Halo';

  @override
  String get quick_duration => 'Berapa lama pengerjaannya?';

  @override
  String get quoteArrived => 'Penawaran final Anda sudah tersedia';

  @override
  String get quoteDepositNow => 'Deposit 10% sekarang';

  @override
  String get quoteBalanceLater => 'Sisa setelah pengerjaan';

  @override
  String get quotePay => 'Bayar deposit & konfirmasi';

  @override
  String get quotePaid => 'Lunas';

  @override
  String get requestCard => 'Permintaan penawaran';

  @override
  String get sys_consultation_received => 'Permintaan Anda sudah diterima';

  @override
  String sys_deposit_paid(String amount) {
    return 'Deposit $amount sudah dibayar. Pemesanan Anda terkonfirmasi.';
  }

  @override
  String get sys_booking_cancelled => 'Pemesanan dibatalkan';

  @override
  String sys_status_changed(String status) {
    return 'Status berubah menjadi $status';
  }

  @override
  String get sys_job_completed =>
      'Pembersihan selesai! Lihat foto sebelum dan sesudahnya.';

  @override
  String sys_rescheduled(String date) {
    return 'Jadwal diubah menjadi $date';
  }

  @override
  String get sys_reschedule_declined =>
      'Mitra tidak bisa datang pada jadwal baru. Tim kami akan mengatur ulang.';

  @override
  String get moreTitle => 'Lainnya';

  @override
  String get moreScope => 'Cakupan layanan';

  @override
  String get morePayments => 'Metode pembayaran';

  @override
  String get moreCoupons => 'Kupon';

  @override
  String get morePoints => 'Poin';

  @override
  String get moreAccount => 'Akun';

  @override
  String get moreAddresses => 'Alamat';

  @override
  String get moreNotices => 'Pengumuman';

  @override
  String get moreTips => 'Tips membersihkan';

  @override
  String get moreFaq => 'Pertanyaan umum';

  @override
  String get morePartner => 'Kerja sama';

  @override
  String get brandTagline => 'Urusan rumah, serahkan pada kami';

  @override
  String get moreLanguage => 'Bahasa';

  @override
  String get langSystem => 'Ikuti pengaturan perangkat';

  @override
  String moreVersion(String v) {
    return 'Versi $v';
  }

  @override
  String get morePrivacy => 'Kebijakan privasi';

  @override
  String get moreTerms => 'Syarat layanan';

  @override
  String get moreLicenses => 'Lisensi open source';

  @override
  String get logout => 'Keluar';

  @override
  String get deleteAccount => 'Hapus akun';

  @override
  String get deleteAccountBody =>
      'Data pribadi Anda akan dihapus dan tidak dapat dipulihkan. Batalkan dulu pemesanan yang masih berjalan.';

  @override
  String get couponsEmpty => 'Belum ada kupon';

  @override
  String couponUntil(String date) {
    return 'Sampai $date';
  }

  @override
  String get couponUsed => 'Sudah dipakai';

  @override
  String get couponExpired => 'Kedaluwarsa';

  @override
  String get couponAnyService => 'Semua layanan';

  @override
  String get coupon_welcome_studio => 'Kupon selamat datang: studio';

  @override
  String get coupon_welcome_any => 'Kupon selamat datang';

  @override
  String get pointsBalance => 'Poin Anda';

  @override
  String get pointsEmpty => 'Belum ada riwayat poin';

  @override
  String get accountName => 'Nama';

  @override
  String get accountPhone => 'Ponsel';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountLogin => 'Metode masuk';

  @override
  String get accountLoginPhone => 'Verifikasi ponsel';

  @override
  String get methodsEmpty => 'Belum ada metode pembayaran';

  @override
  String get noContent => 'Belum ada isi';

  @override
  String get quoteTypeTitle => 'Jenis pembersihan apa yang Anda butuhkan?';

  @override
  String get type_standard => 'Pindah keluar standar';

  @override
  String get type_same_day_move => 'Pindah di hari yang sama';

  @override
  String get type_some_luggage_left => 'Masih ada barang tersisa';

  @override
  String get type_normal_move_in => 'Pindah masuk standar';

  @override
  String get type_after_interior => 'Setelah renovasi';

  @override
  String get type_lived_in_deep_clean =>
      'Pembersihan menyeluruh saat masih dihuni';

  @override
  String get luggageTitle => 'Seberapa penuh barang di rumah?';

  @override
  String get luggage_empty => 'Kosong';

  @override
  String get luggage_partly_unpacked => 'Sebagian sudah dirapikan';

  @override
  String get luggage_fully_lived_in => 'Masih dihuni penuh';

  @override
  String get luggage_unknown => 'Tidak yakin';

  @override
  String get quoteBasicTitle => 'Ceritakan tentang rumahnya';

  @override
  String get buildingType => 'Jenis bangunan';

  @override
  String get building_apartment => 'Apartemen';

  @override
  String get building_villa => 'Rumah deret kecil';

  @override
  String get building_officetel => 'Officetel';

  @override
  String get building_house => 'Rumah tinggal';

  @override
  String get building_other => 'Lainnya';

  @override
  String get layoutTitle => 'Tata letak';

  @override
  String get layout_studio => 'Studio';

  @override
  String get layout_one_and_half => '1,5 kamar';

  @override
  String get layout_two_rooms => '2 kamar';

  @override
  String get layout_three_rooms => '3 kamar';

  @override
  String get layout_four_plus => '4+ kamar';

  @override
  String get duplexTitle => 'Apakah rumahnya duplex?';

  @override
  String get quoteSpaceTitle => 'Sedikit lagi tentang ruangannya';

  @override
  String get bathroomsLabel => 'Kamar mandi';

  @override
  String get balconiesLabel => 'Balkon · ruang servis';

  @override
  String get elevatorTitle => 'Ada lift?';

  @override
  String get floor3Label => 'Lantai 3 atau lebih tinggi';

  @override
  String get quoteEstimateTitle => 'Ini estimasi Anda';

  @override
  String get quoteEstimateBody =>
      'Harga final ditentukan lewat chat setelah kami melihat foto dan kondisi rumah';

  @override
  String get quoteG1 => 'Harga final disepakati lewat chat';

  @override
  String get quoteG2 =>
      'Deposit 10% untuk konfirmasi, sisanya setelah pembersihan';

  @override
  String get quoteG3 => 'Gratis batal sebelum Anda konfirmasi';

  @override
  String get quoteConfirmTitle => 'Periksa permintaan Anda';

  @override
  String get quoteRequest => 'Kirim permintaan';

  @override
  String get quoteNoPayNow => 'Belum ada yang perlu dibayar sekarang';

  @override
  String get summaryType => 'Jenis';

  @override
  String get summaryHome => 'Rumah';

  @override
  String get summaryDate => 'Kunjungan';

  @override
  String get cpTitle => 'Kebijakan pembatalan';

  @override
  String cpWhen(String days) {
    return '$days hari atau lebih sebelum kunjungan';
  }

  @override
  String get cpWhenSameDay => 'Pada hari kunjungan';

  @override
  String get cpFree => 'Pengembalian penuh';

  @override
  String cpFee(String percent, String fee, String refund) {
    return 'Biaya $percent% ($fee), pengembalian $refund';
  }

  @override
  String get cpClosed => 'Tidak bisa dibatalkan di aplikasi (ditinjau tim)';

  @override
  String get hhTitle => 'Info rumah tangga';

  @override
  String get hhAddPet => 'Tambah hewan peliharaan';

  @override
  String get hhPetCount => 'Jumlah';

  @override
  String get hhFloorLabel => 'Lantai (negatif untuk basement)';

  @override
  String get hhElevator => 'Ada lift';

  @override
  String get hhNotes => 'Catatan';

  @override
  String get hhHint => 'Disimpan di alamat ini dan bisa diubah per pemesanan.';

  @override
  String get bkStepConsult => 'Konsultasi diminta';

  @override
  String get bkStepConfirmed => 'Pemesanan dikonfirmasi';

  @override
  String get bkStepMatched => 'Tim ditetapkan';

  @override
  String get bkStepCompleted => 'Layanan selesai';

  @override
  String get bkViewWeek => 'Tampilan minggu';

  @override
  String get bkViewMonth => 'Tampilan bulan';

  @override
  String get chatHoursTitle => 'Jam layanan chat';

  @override
  String get chatReplyFast => 'Biasanya membalas dalam 10 menit';

  @override
  String get quoteVisit => 'Kunjungan';

  @override
  String get quoteKind => 'Jenis';

  @override
  String quotePayAmount(String amount) {
    return 'Bayar DP $amount';
  }

  @override
  String get quoteSuperseded => 'Diganti penawaran yang lebih baru';

  @override
  String get quick_quote => 'Tanya soal penawaran';

  @override
  String get cQuoteOverride => 'Kirim penawaran yang jauh dari perkiraan';

  @override
  String cQuoteOverrideBody(String price, String estimate, String ratio) {
    return 'Penawaran $price · perkiraan $estimate · $ratio×. Tetap kirim?';
  }

  @override
  String get cQuoteNeedsAdmin =>
      'Harga jauh dari perkiraan: perlu persetujuan admin';

  @override
  String get quick_reschedule => 'Ubah jadwal';

  @override
  String get dfScopeDusting => 'Membersihkan debu di atas perabot';

  @override
  String get dfScopeVacuum => 'Menyedot debu dan mengepel lantai';

  @override
  String get dfScopeDishes => 'Mencuci piring dan bak cuci';

  @override
  String get dfScopeBathroom => 'Keran, wastafel dan kloset luar dalam';

  @override
  String get dfScopeTrash => 'Memilah dan membuang sampah';

  @override
  String get dfScopeBedding => 'Merapikan tempat tidur';

  @override
  String get dfScopeTidy => 'Merapikan barang ke tempatnya';

  @override
  String get dfScopeStove => 'Mengelap kompor dan meja dapur';

  @override
  String get dfScopeFridge => 'Mengelap bagian luar kulkas';

  @override
  String get dfScopeTiles => 'Ubin lantai dan dinding kamar mandi';

  @override
  String get dfScopeMold => 'Menghilangkan jamur dan kerak air';

  @override
  String get dfScopeHood => 'Menghilangkan minyak di kap dan kompor';

  @override
  String get dfScopeCabinets => 'Bagian dalam lemari tanam dan kabinet';

  @override
  String get dfScopeWindows => 'Debu kusen dan rel jendela';

  @override
  String get dfScopeShoes => 'Bagian dalam rak sepatu';

  @override
  String get dfScopeEntrance => 'Lantai pintu masuk';

  @override
  String get dfBasicService => 'Layanan dasar';

  @override
  String get dfNotProvided => 'Tidak termasuk';

  @override
  String get dfNp1 => 'Mencuci dan melipat pakaian';

  @override
  String get dfNp2 => 'Tempat yang tak terjangkau';

  @override
  String get dfNp3 => 'Pembersihan khusus';

  @override
  String get dfNp4 => 'Pekerjaan rumah selain bersih-bersih';

  @override
  String get dfRoom => 'Kamar';

  @override
  String get dfKitchen => 'Dapur';

  @override
  String get dfBath => 'Kamar mandi';

  @override
  String get dfEntrance => 'Pintu masuk';

  @override
  String get dfEntranceTrash => 'Pintu masuk / sampah';

  @override
  String get dfScopeMove => 'Pindahan';

  @override
  String get dfScopeBathKitchen => 'Kamar mandi & dapur';

  @override
  String get dfDuration => 'Durasi';

  @override
  String get dfPriceVat => 'Harga (termasuk PPN)';

  @override
  String dfStudioNote(String max) {
    return '※ Rumah di atas $max pyeong tidak bisa memesan pembersihan studio. Kami sarankan layanan yang cocok lewat chat.';
  }

  @override
  String get dfBookNow => 'Pesan';

  @override
  String get dfMustCheck => 'Harap diperhatikan';

  @override
  String get dfAddressTitle => 'Pilih alamat pemesanan.';

  @override
  String get dfEdit => 'Ubah';

  @override
  String dfStudioToast(String service, String max, String label, String size) {
    return '$service hanya untuk rumah hingga $max pyeong. $label ($size pyeong) kami bantu lewat chat.';
  }

  @override
  String dfOverPyeong(String max) {
    return 'Hanya rumah hingga $max pyeong';
  }

  @override
  String get dfDateTitle => 'Pilih tanggal dan waktu.';

  @override
  String get dfManagerIntro => 'Manajer terlatih akan berkunjung.';

  @override
  String get dfServiceTime => 'Waktu layanan';

  @override
  String get dfChange => 'Ubah';

  @override
  String get dfVisitDay => 'Tanggal kunjungan';

  @override
  String get dfVisitTime => 'Waktu kunjungan';

  @override
  String get dfSelect => 'Pilih';

  @override
  String get dfSlotClosed => 'Penuh';

  @override
  String get dfSelectDone => 'Selesai';

  @override
  String get dfDateNote =>
      'Tanggal dan waktu tertentu bisa dikenai biaya tambahan.';

  @override
  String get dfAmVisit => 'Kunjungan pagi';

  @override
  String get dfPmVisit => 'Kunjungan siang';

  @override
  String dfArrive(String range) {
    return 'Tiba $range';
  }

  @override
  String dfPrepHeader(String name) {
    return '$name,\nmohon siapkan ini!';
  }

  @override
  String get dfPrepTools => 'Alat kebersihan yang disiapkan';

  @override
  String get dfNoTools => 'Tidak punya alatnya?';

  @override
  String get dfNoToolsBody => 'Tanyakan tim kami apa yang perlu disiapkan';

  @override
  String get dfPayTitle => 'Pilih diskon dan pembayaran.';

  @override
  String get dfPoints => 'Poin';

  @override
  String get dfPointsFirst => 'Gunakan poin dulu';

  @override
  String get dfPointsOff => 'Tidak dipakai';

  @override
  String get dfPointsNone => 'Tidak ada poin';

  @override
  String get dfPayMethod => 'Metode pembayaran';

  @override
  String dfBaseAmount(String duration) {
    return 'Harga dasar ($duration)';
  }

  @override
  String get dfCouponDiscount => 'Diskon kupon';

  @override
  String get dfDue => 'Jumlah dibayar';

  @override
  String get dfPgNotice =>
      'Pembayaran diproses oleh payment gateway (PG). Dengan membayar, Anda menyetujui ketentuan layanan serta kebijakan pembatalan dan pengembalian dana.';

  @override
  String get dfRefundPolicy => 'Kebijakan pembatalan dan pengembalian dana';

  @override
  String get dfSummaryService => 'Layanan';

  @override
  String get dfSummaryWhen => 'Kunjungan';

  @override
  String get dfSummaryAddress => 'Alamat';

  @override
  String get dfSummaryPaid => 'Dibayar';

  @override
  String get luggage_not_unpacked => 'Barang pindahan belum dibuka';

  @override
  String get dfReviewsTitle => 'Lihat ulasan pelanggan.';

  @override
  String get dfBasicBody => 'Informasi wajib ini bisa memengaruhi harga.';

  @override
  String get building_commercial => 'Ruang komersial';

  @override
  String get dfBldVillaHouse => 'Vila / rumah';

  @override
  String get dfLayoutOneHalf => '1,5 kamar (studio terpisah / ruang tamu + 1)';

  @override
  String get dfLayoutTwo => 'Ruang tamu + 2 kamar';

  @override
  String get dfLayoutThree => 'Ruang tamu + 3 kamar';

  @override
  String get dfLayoutFour => 'Ruang tamu + 4 kamar atau lebih';

  @override
  String get dfDuplexTitle => 'Rumah bertingkat';

  @override
  String get dfNone => 'Tidak';

  @override
  String get dfHas => 'Ada';

  @override
  String get dfPleaseSelect => 'Silakan pilih';

  @override
  String get dfBathCount => 'Jumlah kamar mandi';

  @override
  String get dfBalconyCount => 'Jumlah balkon / ruang cuci';

  @override
  String dfCountN(String n) {
    return '$n';
  }

  @override
  String get dfElevatorTitle => 'Lift';

  @override
  String get dfFloor3 => 'Lokasi di lantai 3 atau lebih';

  @override
  String get dfAcAddonBanner => 'Tambah cuci AC dapat diskon';

  @override
  String get dfAcAddonBody => 'Pindah dengan AC yang bersih juga.';

  @override
  String get dfAcAddonAdd => 'Tambah';

  @override
  String dfAcAddonAdded(String count) {
    return '$count AC ditambahkan';
  }

  @override
  String get dfAcAddonNote => 'Harga setelah diskon terlihat di penawaran Anda';

  @override
  String dfEstAddons(String pct) {
    return 'Tambahan cuci AC (diskon $pct%)';
  }

  @override
  String dfCountUnits(String count) {
    return '$count unit';
  }

  @override
  String get f_ac_addon_discount_bps => 'Diskon tambahan AC (bps, 1000 = 10%)';

  @override
  String get dfQuoteMethodTitle => 'Periksa cara penawaran\nlalu lanjutkan.';

  @override
  String get dfSafeBooking => 'Pemesanan Aman Dahae';

  @override
  String get dfRecommended => 'Rekomendasi';

  @override
  String get dfEstimateVat => 'Perkiraan (termasuk PPN) · bisa berubah';

  @override
  String get dfBenefit1 => 'Dikerjakan tim terlatih bersertifikat';

  @override
  String get dfBenefit2 => '7 hari perbaikan gratis setelah layanan';

  @override
  String get dfBenefit3 => 'Pantau progres langsung di chat';

  @override
  String get dfBenefit4 => 'Deterjen ramah lingkungan';

  @override
  String get dfBenefit5 => 'Poin untuk menulis ulasan';

  @override
  String dfDepositNote(String pct) {
    return '※ Belum ada tagihan. Setelah harga disepakati, deposit $pct% mengonfirmasi pemesanan.';
  }

  @override
  String dfReviewHeader(String date) {
    return '$date\nSelesaikan pemesanan.';
  }

  @override
  String dfVisitTimeLine(String slot) {
    return 'Waktu kunjungan: $slot';
  }

  @override
  String get dfReviewNote =>
      '※ Chat konsultasi terbuka setelah permintaan dikirim. Sepakati harga dan jadwal, lalu bayar deposit.';

  @override
  String get dfHomeInfo => 'Info rumah';

  @override
  String get dfName => 'Nama';

  @override
  String get dfBasicInfo => 'Info dasar';

  @override
  String get dfCleanType => 'Jenis pembersihan';

  @override
  String get dfBuilding => 'Bangunan';

  @override
  String get dfSpaceInfo => 'Info ruang';

  @override
  String get dfPayInfo => 'Info pembayaran';

  @override
  String get dfEstAmount => 'Perkiraan harga';

  @override
  String get dfDepositOnConfirm => 'Deposit (dibayar saat konfirmasi)';

  @override
  String get dfNotes => 'Catatan';

  @override
  String get dfNote1 =>
      'Batal gratis selama konsultasi atau hingga 2 hari sebelumnya.';

  @override
  String get dfNote2 => 'Harga akhir di chat; sisa dibayar setelah layanan.';

  @override
  String get dfNote3 =>
      'Jika tidak bisa dihubungi untuk masuk, tim pergi setelah 30 menit. Mohon pastikan cara masuk.';

  @override
  String get dfNoteWarn =>
      'Jika manajer meminta transaksi langsung, segera beri tahu layanan pelanggan.';

  @override
  String get dfSubmitRequest => 'Kirim permintaan';

  @override
  String get dfRequested => 'Konsultasi diminta.';

  @override
  String get dfStatusNote =>
      '※ Tim mengirim penawaran akhir di chat. Bayar deposit untuk konfirmasi.';

  @override
  String dfPayInfoBody(String pct) {
    return 'Harga bisa berubah. Deposit $pct% dari harga final.';
  }

  @override
  String get dfQuoteMethod => 'Jenis penawaran';

  @override
  String get dfDeposit => 'Deposit';

  @override
  String get dfAwaitingPay => 'Menunggu pembayaran';

  @override
  String get dfServiceInfo => 'Info layanan';

  @override
  String get dfSpace => 'Ruang';

  @override
  String get dfChat => 'Chat konsultasi';

  @override
  String get dfRequestDone => 'Permintaan terkirim';

  @override
  String get dfRequestDoneBody =>
      'Chat konsultasi sudah terbuka.\nTim akan mengirim penawaran akhir.';

  @override
  String get dfAcUpsell => 'Bersihkan AC juga setelah pindah?';

  @override
  String get dfAcUpsellCta => 'Pesan cuci AC';

  @override
  String get dfViewChat => 'Buka chat konsultasi';

  @override
  String get dhHomeRecommended => 'Rekomendasi';

  @override
  String get dhHomeNews => 'Kabar Dahae';

  @override
  String get dhSvcMove => 'Pembersihan pindahan (masuk / keluar)';

  @override
  String get dhSvcMoveShort => 'Pindahan';

  @override
  String get dhMovePickTitle => 'Pembersihan pindahan mana yang Anda butuhkan?';

  @override
  String get cKind_news => 'Kabar';

  @override
  String get cLink => 'Tautan (coupons, service/move_in, https://…)';

  @override
  String get welcomePackTitle => 'Kupon selamat datang saat mendaftar';

  @override
  String get welcomePackBody =>
      'Diberikan sekali saat pelanggan selesai mendaftar. Hapus semua untuk menonaktifkan.';

  @override
  String get welcomePackAmount => 'Nilai kupon (KRW)';

  @override
  String get welcomePackAdd => 'Tambah kupon';

  @override
  String get welcomePackRemove => 'Hapus kupon';

  @override
  String moreGreeting(String brand) {
    return 'Serahkan pekerjaan rumah hari ini kepada $brand';
  }

  @override
  String moreBrandTips(String brand) {
    return 'Tips $brand';
  }

  @override
  String get moreContact => 'Hubungi kami';

  @override
  String get moreVersionInfo => 'Info versi';

  @override
  String get payAvailableTitle => 'Metode pembayaran tersedia';

  @override
  String get accountLoginKakao => 'Kakao';

  @override
  String get accountLoginNaver => 'Naver';

  @override
  String get accountLoginApple => 'Apple';

  @override
  String get accountLoginGoogle => 'Google';

  @override
  String get themeTitle => 'Tema';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeTip => 'Ganti tema';

  @override
  String get err_price_changed =>
      'Harga berubah. Cek penawaran baru lalu coba lagi.';

  @override
  String get err_checkout_closed => 'Pembayaran ini sudah ditutup. Mulai lagi.';

  @override
  String get err_checkout_refunded =>
      'Pembayaran ini sudah dibatalkan dan dikembalikan.';

  @override
  String get err_already_paid => 'Pembayaran ini sudah lunas.';

  @override
  String get err_quote_not_payable =>
      'Penawaran ini belum bisa dibayar. Hubungi tim kami.';

  @override
  String get err_payment_method_disabled =>
      'Metode pembayaran ini sedang tidak tersedia.';

  @override
  String get err_invalid_payment_method =>
      'Metode pembayaran ini tidak bisa dipakai. Pilih yang lain.';

  @override
  String get err_balance_not_due => 'Sisa pembayaran belum jatuh tempo.';

  @override
  String get err_invalid_slot => 'Jam ini tidak tersedia untuk layanan ini.';

  @override
  String get err_booking_changed =>
      'Pesanan berubah. Muat ulang dan periksa detailnya.';

  @override
  String get err_booking_closed => 'Pesanan ini tidak bisa diubah lagi.';

  @override
  String get err_reschedule_closed =>
      'Jadwal kunjungan tidak bisa diubah sekarang. Hubungi tim kami.';

  @override
  String get err_too_many_open_requests =>
      'Terlalu banyak permintaan yang masih terbuka. Selesaikan satu dulu.';

  @override
  String get err_already_reviewed =>
      'Anda sudah memberi ulasan untuk kunjungan ini.';

  @override
  String get err_identity_not_verified =>
      'Selesaikan verifikasi identitas dulu.';

  @override
  String get err_email_taken => 'Email ini sudah dipakai.';

  @override
  String get err_invalid_email => 'Periksa alamat email.';

  @override
  String get err_file_too_large =>
      'Berkas terlalu besar. Unggah berkas yang lebih kecil.';

  @override
  String get err_unsupported_image =>
      'Format foto ini tidak didukung. Unggah JPG atau PNG.';

  @override
  String get err_upload_quota =>
      'Batas unggah hari ini sudah tercapai. Coba lagi besok.';

  @override
  String get err_provider_unreachable =>
      'Tidak bisa terhubung ke layanan. Coba lagi sebentar lagi.';

  @override
  String get err_invalid_token => 'Gagal masuk. Coba lagi.';

  @override
  String get err_invalid_transition =>
      'Status tidak bisa diubah seperti itu sekarang.';

  @override
  String get err_job_not_started => 'Mulai pekerjaan dulu.';

  @override
  String get err_job_not_active => 'Pekerjaan ini tidak aktif.';

  @override
  String get err_quote_locked =>
      'Penawaran sudah dikunci dan tidak bisa diubah.';

  @override
  String get err_request_closed => 'Permintaan ini sudah ditutup.';

  @override
  String get err_team_full => 'Tim sudah penuh.';

  @override
  String get err_invalid_webhook_secret =>
      'Webhook secret harus diawali whsec_.';

  @override
  String get err_invalid_endpoint => 'Endpoint harus diawali https://.';

  @override
  String get err_invalid_bucket => 'Nama bucket tidak valid.';

  @override
  String get err_invalid_region => 'Region tidak valid.';

  @override
  String get err_invalid_retention => 'Masa retensi di luar batas.';

  @override
  String get err_invalid_service_account => 'File service account tidak valid.';

  @override
  String get err_invalid_mode => 'Pilih mode AI yang valid.';

  @override
  String get err_invalid_model => 'Nama model AI tidak valid.';

  @override
  String get err_missing_field => 'Isi semua kolom yang wajib.';

  @override
  String get err_invalid_amount => 'Masukkan jumlah yang valid.';

  @override
  String get err_cannot_deactivate_self =>
      'Anda tidak bisa menonaktifkan akun sendiri.';

  @override
  String get err_invalid_coupon => 'Kupon ini tidak valid.';

  @override
  String get err_settlement_state => 'Settlement tidak bisa diubah sekarang.';

  @override
  String get err_deposit_required => 'Uang muka harus dibayar dulu.';

  @override
  String get err_payout_state =>
      'Status pencairan berubah. Muat ulang dan cek lagi.';

  @override
  String get err_payout_provider =>
      'Metode pencairan ini sedang tidak tersedia.';

  @override
  String get err_unsupported_bank => 'Bank ini belum didukung untuk pencairan.';

  @override
  String get err_toss_unverified =>
      'Pembayaran Toss belum tersedia. Gunakan transfer manual.';

  @override
  String get err_invalid_cap => 'Masukkan angka dalam rentang yang diizinkan.';

  @override
  String get err_invalid_capacity => 'Masukkan kapasitas yang valid.';

  @override
  String get err_seller_declined =>
      'Toss tidak menyetujui pendaftaran penjual. Periksa data usaha.';

  @override
  String get err_payout_account_unverified =>
      'Partner ini belum punya rekening pencairan yang diverifikasi. Verifikasi rekening dulu.';

  @override
  String get guestSheetTitle => 'Masuk untuk melanjutkan';

  @override
  String get guestSheetBody =>
      'Semua yang Anda isi tetap tersimpan. Anda lanjut tepat di tempat tadi.';

  @override
  String get greetMorning => 'Selamat pagi';

  @override
  String get greetAfternoon => 'Selamat siang';

  @override
  String get greetEvening => 'Selamat malam';

  @override
  String get feedHeading => 'Pilihan untukmu';

  @override
  String get feedTitleDue => 'Waktunya jadwal bersih berikutnya';

  @override
  String get feedTitleRebook => 'Pesan lagi mitra bintang 5';

  @override
  String get feedTitleDraft => 'Lanjutkan penawaran yang belum selesai';

  @override
  String get feedTitleSeasonal => 'Pembersihan yang pas untuk musim ini';

  @override
  String get feedTitleSize => 'Penawaran dari ukuran rumah tersimpan';

  @override
  String get feedTitleSubscription => 'Hemat lebih banyak dengan langganan';

  @override
  String get feedTitleDistrict => 'Tetangga juga sedang memesan';

  @override
  String feedWhyCadence(String days) {
    return '$days hari sejak pembersihan terakhir';
  }

  @override
  String feedWhyRated(String days) {
    return 'Anda memberi bintang 5 untuk mitra ini $days hari lalu';
  }

  @override
  String get feedWhyDraft =>
      'Ada penawaran yang belum selesai di perangkat ini';

  @override
  String get feedWhySummer =>
      'Waktu yang tepat membersihkan AC sebelum musim panas';

  @override
  String get feedWhyMoving => 'Musim pindahan dan masuk rumah sedang ramai';

  @override
  String feedWhyHoliday(String days) {
    return '$days hari lagi menuju bersih-bersih besar lebaran';
  }

  @override
  String feedWhySize(String pyeong) {
    return 'Penawaran instan untuk rumah $pyeong pyeong tersimpan';
  }

  @override
  String get feedWhyRepeat => 'Jika sering memesan, langganan lebih murah';

  @override
  String feedWhyDistrict(String district, String count) {
    return '$count rumah di $district memesan minggu ini';
  }

  @override
  String get fFinance => 'Keuangan';

  @override
  String get fPeriodDay => 'Hari';

  @override
  String get fPeriodWeek => 'Minggu';

  @override
  String get fPeriodMonth => 'Bulan';

  @override
  String get fPeriodCustom => 'Kustom';

  @override
  String get fFrom => 'Dari';

  @override
  String get fTo => 'Sampai';

  @override
  String get fGross => 'Total pembayaran';

  @override
  String get fRefunds => 'Pengembalian';

  @override
  String get fNetRevenue => 'Pendapatan bersih';

  @override
  String get fPlatformFee => 'Biaya platform';

  @override
  String get fPaidOut => 'Dibayarkan ke mitra';

  @override
  String get fPendingOut => 'Pembayaran tertunda';

  @override
  String get fHeldOut => 'Ditahan';

  @override
  String get fVatEstimate => 'Estimasi PPN';

  @override
  String get fVatNote =>
      'Estimasi 10% dari biaya platform. Konfirmasi dengan akuntan Anda.';

  @override
  String get fAov => 'Rata-rata nilai pesanan';

  @override
  String get fBookings => 'Pemesanan';

  @override
  String get fCancelRate => 'Tingkat pembatalan';

  @override
  String get fDiscounts => 'Diskon & kupon';

  @override
  String get fMethods => 'Metode pembayaran';

  @override
  String get fTrend => 'Tren';

  @override
  String fRangeDays(String n) {
    return '$n hari terakhir';
  }

  @override
  String get fRangeWeeks => '12 minggu terakhir';

  @override
  String get fRangeMonths => '12 bulan terakhir';

  @override
  String get fByPartner => 'Pendapatan per mitra';

  @override
  String get fByService => 'Pendapatan per layanan';

  @override
  String get fExportTitle => 'Ekspor akuntansi';

  @override
  String get fExportLedger => 'CSV buku pembayaran';

  @override
  String get fExportSettlements => 'CSV penyelesaian';

  @override
  String get fExportMonthly => 'CSV ringkasan bulanan (akuntan)';

  @override
  String get fDownload => 'Unduh CSV';

  @override
  String get fDownloadWebOnly => 'Unduh CSV tersedia di konsol web';

  @override
  String get fDownloadFailed => 'Gagal mengunduh';

  @override
  String get fNoRecords => 'Tidak ada catatan pada periode ini';

  @override
  String get fLoadFailed => 'Data keuangan gagal dimuat';

  @override
  String get fRetry => 'Coba lagi';

  @override
  String get fColPartner => 'Mitra';

  @override
  String get fColJobs => 'Jumlah';

  @override
  String get fColSettled => 'Total penyelesaian';

  @override
  String get fColFee => 'Biaya';

  @override
  String get fColNet => 'Bersih';

  @override
  String get pEarnings => 'Penghasilan';

  @override
  String get pNextPayout => 'Pembayaran berikutnya';

  @override
  String pNextPayoutOn(String date) {
    return 'Dibayar $date';
  }

  @override
  String get pNoPayout => 'Belum ada pembayaran terjadwal';

  @override
  String get pPendingTotal => 'Menunggu dibayar';

  @override
  String get pPaidTotal => 'Sudah dibayar';

  @override
  String get pWeekly => 'Mingguan';

  @override
  String get pMonthly => 'Bulanan';

  @override
  String proofHomes(String count) {
    return '$count rumah dibersihkan bulan ini';
  }

  @override
  String proofRating(String rating, String count) {
    return 'Rata-rata $rating bintang · $count ulasan';
  }

  @override
  String get proofReviewsTitle => 'Ulasan terbaru';

  @override
  String get rebookTitle => 'Pesan lagi layanan terakhir?';

  @override
  String rebookBody(String service, String date) {
    return '$service · kunjungan terakhir $date';
  }

  @override
  String get rebookButton => 'Pesan lagi';

  @override
  String seatsLeft(String count) {
    return 'Sisa $count tempat';
  }

  @override
  String get reviewSheetTitle => 'Bagaimana pembersihan kali ini?';

  @override
  String get reviewPhotosAdd => 'Tambah foto';

  @override
  String get reviewPhotosHint => 'Maksimal 5 foto';

  @override
  String get reviewSaved => 'Terima kasih atas ulasan Anda';

  @override
  String get reviewPhotoFailed => 'Foto gagal diunggah. Coba lagi.';

  @override
  String get referralTitle => 'Undang teman, dapatkan kupon';

  @override
  String referralBody(String amount) {
    return 'Saat teman Anda menyelesaikan pesanan pertama, Anda berdua mendapat kupon $amount';
  }

  @override
  String get referralCopy => 'Salin kode';

  @override
  String get referralCopied => 'Kode referral disalin';

  @override
  String get referralClaimTitle => 'Punya kode referral?';

  @override
  String get referralClaimField => 'Masukkan kode referral';

  @override
  String get referralClaimButton => 'Terapkan';

  @override
  String get referralClaimed => 'Kode referral diterapkan';

  @override
  String referralStats(String invited, String rewarded) {
    return '$invited diundang · $rewarded hadiah';
  }

  @override
  String get err_self_referral => 'Anda tidak bisa memakai kode sendiri';

  @override
  String get err_referee_already_booked =>
      'Kode hanya bisa dimasukkan sebelum pesanan pertama';

  @override
  String get err_already_referred => 'Kode referral sudah diterapkan';

  @override
  String get err_invalid_referral_code => 'Periksa kembali kode referral';

  @override
  String get err_referral_disabled => 'Referral sedang dijeda';

  @override
  String get err_invalid_photos =>
      'Hanya foto yang diunggah lewat Dahae yang bisa dilampirkan';

  @override
  String get welcomeOfferTitle => 'Diskon pesanan pertama';

  @override
  String get welcomeOfferBody =>
      'Otomatis berlaku untuk pesanan pertama pelanggan baru. Tidak digabung dengan kupon.';

  @override
  String get offerKindAmount => 'Nominal (won)';

  @override
  String get offerKindPercent => 'Persen (%)';

  @override
  String get offerValue => 'Nilai diskon';

  @override
  String get offerEnabled => 'Aktif';

  @override
  String get offerSaved => 'Tersimpan';

  @override
  String get referralSettingsTitle => 'Hadiah referral';

  @override
  String get referralSettingsBody =>
      'Diberikan setelah pesanan pertama teman selesai dan dibayar. Referral diri sendiri dan nomor ganda diblokir.';

  @override
  String get referralRewardAmount => 'Nominal hadiah (won)';

  @override
  String get reviewsModerationTitle => 'Moderasi ulasan';

  @override
  String get reviewHide => 'Sembunyikan';

  @override
  String get reviewShow => 'Tampilkan lagi';

  @override
  String get reviewHiddenTag => 'Disembunyikan';

  @override
  String get growthAverageRating => 'Rata-rata rating';

  @override
  String growthReviewCount(String count) {
    return '$count ulasan';
  }

  @override
  String get growthReferralConversion => 'Konversi referral';

  @override
  String get growthTab => 'Pertumbuhan';

  @override
  String growthReferralValue(String rewarded, String invited) {
    return '$rewarded dari $invited';
  }

  @override
  String get locUseCurrent => 'Gunakan lokasi saya saat ini';

  @override
  String get locConsentTitle => 'Ketentuan layanan berbasis lokasi';

  @override
  String get locConsentBody =>
      'Untuk mencari alamat dari lokasi Anda saat ini, harap setujui ketentuan layanan berbasis lokasi. Kami memeriksa lokasi Anda satu kali saja, saat Anda mengetuk \"Gunakan lokasi saya saat ini\", dan hanya memakainya untuk menyarankan alamat. Koordinat tidak disimpan di server kami. Anda dapat menarik persetujuan kapan saja di Pengaturan persetujuan.';

  @override
  String get locConsentAgree => 'Setuju dan lanjutkan';

  @override
  String get locSuggestionTitle => 'Apakah ini alamat Anda?';

  @override
  String get locUseAddress => 'Gunakan alamat ini';

  @override
  String get locDenied =>
      'Izin lokasi tidak aktif. Silakan masukkan alamat secara manual.';

  @override
  String get locServicesOff =>
      'Layanan lokasi di perangkat ini mati. Silakan masukkan alamat secara manual.';

  @override
  String get locTimeout =>
      'Pencarian lokasi terlalu lama. Silakan masukkan alamat secara manual.';

  @override
  String get locNoAddress =>
      'Alamat untuk lokasi Anda tidak ditemukan. Silakan masukkan alamat secara manual.';

  @override
  String get uMaintenanceTitle => 'Sedang pemeliharaan';

  @override
  String get uMaintenanceBody =>
      'Kami sedang meningkatkan layanan. Silakan coba lagi nanti.';

  @override
  String get cmTab => 'Kampanye';

  @override
  String get cmNew => 'Kampanye baru';

  @override
  String get cmAudience => 'Audiens';

  @override
  String get cmSegAll => 'Semua pelanggan';

  @override
  String get cmSegNever => 'Belum pernah pesan';

  @override
  String cmSegLapsed(String days) {
    return 'Pesanan terakhir $days+ hari lalu';
  }

  @override
  String get cmDays => 'Jumlah hari';

  @override
  String cmConsentCount(String total, String consented) {
    return '$consented dari $total menyetujui pemasaran';
  }

  @override
  String get cmChannel => 'Saluran';

  @override
  String get cmPush => 'Push aplikasi';

  @override
  String get cmSms => 'SMS';

  @override
  String get cmTitle => 'Judul';

  @override
  String get cmBody => 'Pesan';

  @override
  String get cmOptout => 'Nomor berhenti (080)';

  @override
  String get cmPreview => 'Pratinjau';

  @override
  String get cmSchedule => 'Waktu kirim';

  @override
  String get cmSendNow => 'Kirim sekarang';

  @override
  String get cmTestSend => 'Kirim tes ke nomor saya';

  @override
  String get cmCreate => 'Simpan kampanye';

  @override
  String get cmNeedOptout => 'SMS memerlukan nomor berhenti 080';

  @override
  String get cmLog => 'Log pengiriman';

  @override
  String cmStatSent(String count) {
    return 'Terkirim $count';
  }

  @override
  String cmStatSkipped(String count) {
    return 'Tanpa persetujuan $count';
  }

  @override
  String cmStatFailed(String count) {
    return 'Gagal $count';
  }

  @override
  String get cmSaved => 'Kampanye disimpan';

  @override
  String anFunnel(String days) {
    return 'Corong pendaftaran ($days hari terakhir)';
  }

  @override
  String get anInstalls => 'Membuka aplikasi (setuju)';

  @override
  String get anSignedUp => 'Mendaftar';

  @override
  String get anQuoted => 'Minta penawaran';

  @override
  String get anBooked => 'Memesan';

  @override
  String get anPaid => 'Membayar';

  @override
  String get anRepeat => 'Berulang (2+)';

  @override
  String get anCohorts => 'Kohort mingguan (tingkat pesanan per minggu daftar)';

  @override
  String anCohortSize(String count) {
    return 'Pendaftar $count';
  }

  @override
  String anWeekAfter(String n) {
    return 'Pesan di minggu $n';
  }

  @override
  String get cOps => 'Status sistem';

  @override
  String get oLevelGreen => 'Normal';

  @override
  String get oLevelYellow => 'Perlu dicek';

  @override
  String get oLevelRed => 'Perlu tindakan';

  @override
  String get oOverall => 'Status server';

  @override
  String get oRefresh => 'Muat ulang';

  @override
  String get oVersion => 'Versi';

  @override
  String get oUptime => 'Waktu aktif';

  @override
  String oUptimeValue(String hours, String minutes) {
    return '$hours jam $minutes menit';
  }

  @override
  String get oChecks => 'Pemeriksaan';

  @override
  String get oCheckDb => 'Basis data';

  @override
  String oCheckDbValue(String ms, String mb) {
    return 'Respons $ms ms · ukuran $mb MB';
  }

  @override
  String get oCheckDisk => 'Disk server';

  @override
  String oCheckDiskValue(String pct) {
    return 'Sisa $pct%';
  }

  @override
  String get oCheckBackup => 'Cadangan otomatis';

  @override
  String oCheckBackupValue(String hours) {
    return 'Cadangan terakhir $hours jam lalu';
  }

  @override
  String get oCheckBackupNone => 'Belum ada cadangan';

  @override
  String get oCheckErrors => 'Error server (24 jam)';

  @override
  String oCheckErrorsValue(String count) {
    return '$count';
  }

  @override
  String get oCheckPayments => 'Pembayaran perlu dicek';

  @override
  String oCheckPaymentsValue(String count) {
    return '$count (24 jam)';
  }

  @override
  String get oCheckWebhook => 'Notifikasi pembayaran (webhook)';

  @override
  String oCheckWebhookValue(String count) {
    return 'Tanda tangan gagal $count (24 jam)';
  }

  @override
  String get oIntegrations => 'Layanan eksternal';

  @override
  String get oIntNotSet => 'Belum diatur';

  @override
  String oIntLastOk(String at) {
    return 'Berhasil terakhir $at';
  }

  @override
  String oIntLastFail(String at, String code) {
    return 'Gagal terakhir $at ($code)';
  }

  @override
  String get oIntNever => 'Belum ada penggunaan';

  @override
  String get oActDb =>
      'Tidak dapat terhubung ke database. Jalankan malkkeum logs di server; restart jika terus terjadi.';

  @override
  String get oActDisk =>
      'Sisa disk di bawah 10%. Hapus cadangan lama atau tambah kapasitas disk.';

  @override
  String get oActBackup =>
      'Cadangan otomatis terlambat. Jalankan malkkeum backup di server dan cek backups/backup.log.';

  @override
  String get oActErrors =>
      'Banyak error server. Cek baris error di malkkeum logs dan kirim ke pengembang jika berulang.';

  @override
  String get oActPayments =>
      'Pembayaran mungkin sudah masuk tetapi belum diproses otomatis. Cek di PortOne dan refund manual jika perlu.';

  @override
  String get oActWebhook =>
      'Pemeriksaan tanda tangan notifikasi pembayaran gagal. Masukkan ulang webhook secret di Setup > Payments (PortOne).';

  @override
  String get oActIntegration =>
      'Koneksi ini gagal. Cek kunci di Setup lalu tekan Test connection.';

  @override
  String get oActNotSet => 'Belum diatur. Masukkan kunci di Setup.';

  @override
  String get oAlerts => 'Pengaturan peringatan';

  @override
  String get oAlertsHint =>
      'Masalah dikirim ke kotak masuk dan SMS ke ponsel pemilik. Masalah yang sama hanya dikirim sekali tiap 6 jam.';

  @override
  String get oRuleSms => 'Pengiriman SMS gagal';

  @override
  String get oRulePush => 'Notifikasi push gagal';

  @override
  String get oRulePayment => 'Koneksi pembayaran gagal';

  @override
  String get oRuleStuck => 'Pembayaran tidak diproses otomatis';

  @override
  String get oRuleSocial => 'Login sosial gagal';

  @override
  String get oRuleBackup => 'Cadangan otomatis terlewat';

  @override
  String get oRuleDisk => 'Disk hampir penuh';

  @override
  String get oRuleAuth => 'Aktivitas login mencurigakan';

  @override
  String get oQuietHours => 'Jam tenang';

  @override
  String get oQuietFrom => 'Dari';

  @override
  String get oQuietTo => 'Sampai';

  @override
  String oHour(String hour) {
    return '$hour:00';
  }

  @override
  String get oQuietHint =>
      'Tidak ada peringatan pada jam ini; satu pesan dikirim setelah selesai.';

  @override
  String get oAlertPhone => 'Telepon untuk peringatan';

  @override
  String get oAlertPhoneHint =>
      'Kosongkan untuk memakai nomor layanan pelanggan di info bisnis.';

  @override
  String get oSave => 'Simpan';

  @override
  String get oSaved => 'Pengaturan peringatan disimpan';

  @override
  String get oSaveFailed => 'Gagal menyimpan. Periksa isiannya.';

  @override
  String get oLoadFailed => 'Status gagal dimuat';

  @override
  String get oBackupOffsite => 'Cadangan eksternal (S3)';

  @override
  String get oBackupOffsiteOff =>
      'Mati. Aktifkan di Setup > Cadangan eksternal.';

  @override
  String get oLastBackup => 'Cadangan terakhir';

  @override
  String get oDiskFree => 'Ruang kosong';

  @override
  String get oNoData => 'Belum ada data';

  @override
  String get cIntBackup => 'Cadangan eksternal (kompatibel S3)';

  @override
  String get pTabJobs => 'Pekerjaan';

  @override
  String get pTabQuotes => 'Penawaran saya';

  @override
  String get pTabSchedule => 'Jadwal';

  @override
  String get pIntroTitle =>
      'Pekerjaan, jadwal, dan pencairan\nuntuk mitra kebersihan';

  @override
  String get pIntroBody =>
      'Bekerja hanya di area dan waktu yang Anda pilih. Dibayar setiap minggu.';

  @override
  String get pOnbTitle => 'Ceritakan tentang Anda';

  @override
  String get pOnbName => 'Nama Anda';

  @override
  String get pOnbTeam => 'Nama tim';

  @override
  String get pOnbServices => 'Layanan yang Anda tawarkan';

  @override
  String get pOnbAreas => 'Area kerja';

  @override
  String get pOnbDone => 'Daftar';

  @override
  String get pPendingTitle => 'Akun Anda sedang ditinjau';

  @override
  String get pPendingBody =>
      'Kami akan memberi tahu setelah disetujui. Sementara itu, tambahkan rekening pencairan Anda.';

  @override
  String get pSuspended =>
      'Akun Anda sedang ditangguhkan. Silakan hubungi tim operasional.';

  @override
  String get pDirect => 'Langsung';

  @override
  String get pQuoteReq => 'Permintaan penawaran';

  @override
  String get pShowClosed => 'Tampilkan pekerjaan yang sudah tutup';

  @override
  String get pSortNewest => 'Terbaru';

  @override
  String get pSortVisit => 'Kunjungan terdekat';

  @override
  String get pSortAmount => 'Nilai tertinggi';

  @override
  String get pNoJobs => 'Belum ada pekerjaan yang cocok';

  @override
  String get pNoJobsBody =>
      'Perluas layanan, area, atau jam kerja untuk melihat lebih banyak pekerjaan';

  @override
  String get pPayout => 'Estimasi pencairan';

  @override
  String get pCustomerEstimate => 'Estimasi pelanggan';

  @override
  String get pNew => 'BARU';

  @override
  String get pClosed => 'Tutup';

  @override
  String get pPrivacyNote =>
      'Alamat lengkap dan data pelanggan muncul setelah Anda menerima pekerjaan';

  @override
  String get pAccept => 'Terima pekerjaan';

  @override
  String get pAcceptConfirm => 'Terima pekerjaan ini?';

  @override
  String get pAcceptBody =>
      'Pekerjaan akan masuk ke jadwal Anda dan pelanggan diberi tahu bahwa tim sudah ditugaskan. Pembatalan dalam 2 hari sebelum kunjungan dibatasi.';

  @override
  String get pAccepted => 'Pekerjaan diterima';

  @override
  String get pSendQuote => 'Kirim penawaran';

  @override
  String get pQuotePrice => 'Harga untuk pelanggan';

  @override
  String get pQuoteNote => 'Catatan untuk tim';

  @override
  String get pQuoteSent => 'Penawaran terkirim';

  @override
  String pFee(String rate) {
    return 'Biaya $rate%';
  }

  @override
  String get pYouGet => 'Anda terima';

  @override
  String get pQuoteAll => 'Semua';

  @override
  String get pQ_waiting => 'Menunggu';

  @override
  String get pQ_selected => 'Dipilih';

  @override
  String get pQ_rejected => 'Tidak dipilih';

  @override
  String get pQ_closed => 'Ditutup';

  @override
  String get pUnseenOnly => 'Hanya hasil baru';

  @override
  String get pNoQuotes => 'Belum ada penawaran';

  @override
  String get pMyQuote => 'Penawaran saya';

  @override
  String get pWithdraw => 'Tarik penawaran';

  @override
  String get pWithdrawn => 'Penawaran ditarik';

  @override
  String get pOnlyMine => 'Hanya milik saya';

  @override
  String pJobsCount(String n) {
    return '$n pekerjaan';
  }

  @override
  String get pNoSchedule => 'Tidak ada jadwal';

  @override
  String get pCancelledBanner =>
      'Pelanggan membatalkan pekerjaan ini. Tidak bisa ditandai selesai.';

  @override
  String pRescheduleBanner(String from, String to) {
    return 'Permintaan ubah jadwal: $from → $to';
  }

  @override
  String get pRescheduleOk => 'Bisa datang';

  @override
  String get pRescheduleNo => 'Tidak bisa datang';

  @override
  String get pCustomer => 'Pelanggan';

  @override
  String get pCall => 'Telepon (nomor tersamar)';

  @override
  String get pCallSoon => 'Panggilan nomor tersamar akan aktif saat peluncuran';

  @override
  String get pQuietHours => 'Mohon jangan menelepon setelah pukul 20.00';

  @override
  String get pAssignee => 'Penanggung jawab';

  @override
  String get pChangeAssignee => 'Ubah penanggung jawab';

  @override
  String get pCustomerRequests => 'Permintaan pelanggan';

  @override
  String get pHousehold => 'Info rumah tangga';

  @override
  String get pPets => 'Hewan peliharaan';

  @override
  String get pPetDog => 'Anjing';

  @override
  String get pPetCat => 'Kucing';

  @override
  String get pPetBird => 'Burung';

  @override
  String get pPetFish => 'Ikan';

  @override
  String get pPetOther => 'Hewan lain';

  @override
  String get pAllergies => 'Alergi & sensitivitas';

  @override
  String get pPreferredProducts => 'Produk pilihan';

  @override
  String get pParking => 'Parkir';

  @override
  String pFloor(String floor) {
    return 'Lantai $floor';
  }

  @override
  String get pElevatorYes => 'Ada lift';

  @override
  String get pElevatorNo => 'Tidak ada lift';

  @override
  String get pTeamMemo => 'Catatan tim (tidak terlihat pelanggan)';

  @override
  String get pMemoSaved => 'Catatan tersimpan';

  @override
  String get pPayoutBreakdown => 'Rincian pencairan';

  @override
  String get pAfterBalance =>
      'Dicairkan setelah pelanggan membayar sisa pembayaran';

  @override
  String get pChatOps => 'Chat dengan operasional';

  @override
  String get pComplete => 'Selesaikan pekerjaan';

  @override
  String get pBeforePhotos => 'Foto sebelum';

  @override
  String get pAfterPhotos => 'Foto sesudah';

  @override
  String get pAddPhoto => 'Tambah foto';

  @override
  String get pChecklist => 'Daftar periksa';

  @override
  String get pCheck1 => 'Semua area yang diminta sudah dibersihkan';

  @override
  String get pCheck2 => 'Sampah sudah ditangani dan alat sudah dikumpulkan';

  @override
  String get pCheck3 => 'Jendela, listrik, dan air sudah dicek';

  @override
  String get pCheck4 => 'Permintaan pelanggan sudah dipenuhi';

  @override
  String get pCompleteCta => 'Tandai selesai';

  @override
  String get pCompleteNeed =>
      'Unggah minimal 1 foto untuk masing-masing jenis dan centang semua item';

  @override
  String get pCompleted => 'Kerja bagus!';

  @override
  String pPayoutOn(String date, String amount) {
    return '$amount akan dicairkan pada $date';
  }

  @override
  String get pPayoutWaiting =>
      'Tanggal pencairan ditentukan setelah pelanggan membayar';

  @override
  String get pPendingPayout => 'Pencairan tertunda';

  @override
  String get pSettlements => 'Riwayat pencairan';

  @override
  String get pS_waiting_balance => 'Menunggu sisa pembayaran';

  @override
  String get pS_pending => 'Dijadwalkan';

  @override
  String get pS_paid => 'Dibayar';

  @override
  String get pS_held => 'Ditahan';

  @override
  String get pReviews => 'Ulasan pelanggan';

  @override
  String get pNoReviews => 'Belum ada ulasan';

  @override
  String get pReplyLater => 'Fitur balasan segera hadir';

  @override
  String get pServicesAreas => 'Layanan & area';

  @override
  String get pPayoutAccount => 'Rekening pencairan';

  @override
  String get pBank => 'Bank';

  @override
  String get pAccountNumber => 'Nomor rekening';

  @override
  String get pHolder => 'Atas nama';

  @override
  String get pVerified => 'Terverifikasi';

  @override
  String get pUnverified => 'Sedang diverifikasi';

  @override
  String get pAccountSaved =>
      'Rekening tersimpan. Perubahan akan diverifikasi ulang.';

  @override
  String get pWorkSchedule => 'Jadwal kerja';

  @override
  String get pWeekdays => 'Hari kerja';

  @override
  String get pDayParts => 'Jam kerja';

  @override
  String get pDaysOff => 'Hari libur';

  @override
  String get pAddDayOff => 'Tambah hari libur';

  @override
  String get pSaved => 'Tersimpan';

  @override
  String get pTeam => 'Anggota tim';

  @override
  String get pOwner => 'Pemilik';

  @override
  String get pInvited => 'Diundang';

  @override
  String get pInvite => 'Undang anggota';

  @override
  String get pInviteSent => 'Undangan terkirim';

  @override
  String get pRemove => 'Keluarkan';

  @override
  String get pNotifications => 'Notifikasi';

  @override
  String get pNotifyDirect => 'Pekerjaan langsung baru';

  @override
  String get pNotifyQuotes => 'Permintaan penawaran & hasil';

  @override
  String get pNotifyChat => 'Pesan dari operasional';

  @override
  String get pQuietNight => 'Senyap di malam hari (22.00–08.00)';

  @override
  String get pNewInquiry => 'Pertanyaan baru';

  @override
  String get pTopic_settlement => 'Pencairan';

  @override
  String get pTopic_reschedule => 'Ubah jadwal · batal';

  @override
  String get pTopic_app => 'Bantuan aplikasi';

  @override
  String get pOpsTeam => 'Operasional';

  @override
  String get pViewJob => 'Lihat pekerjaan';

  @override
  String pBookingNo(String n) {
    return 'Pemesanan $n';
  }

  @override
  String get pSize => 'Luas';

  @override
  String get pSchedule => 'Jadwal';

  @override
  String get pSpace => 'Info ruang';

  @override
  String get pNavigate => 'Petunjuk arah';

  @override
  String get pNavHint =>
      'Membuka alamat kunjungan di aplikasi peta. Tanpa aplikasi, peta web yang dibuka.';

  @override
  String get pOfflineSaved =>
      'Tidak ada sinyal. Disimpan dan akan dikirim saat online.';

  @override
  String get pPhotoRetry => 'Coba unggah lagi';

  @override
  String get pPhotoWaiting =>
      'Foto yang belum terunggah akan dikirim otomatis saat online.';

  @override
  String pUploadedCount(String total, String done) {
    return '$done dari $total terunggah';
  }

  @override
  String get apPgPickMethod => 'Pilih metode pembayaran';

  @override
  String get apPgConfirmTitle => 'Tinjau pembayaran Anda';

  @override
  String get apPgConfirmBtn => 'Konfirmasi pembayaran';

  @override
  String get apPgProcessing => 'Memproses pembayaran…';

  @override
  String get apPgDoneTitle => 'Pembayaran berhasil';

  @override
  String get apPgReceiptTitle => 'Struk elektronik';

  @override
  String get apPgReceiptApproval => 'No. persetujuan';

  @override
  String get apPgReceiptMethod => 'Metode';

  @override
  String get apPgReceiptAmount => 'Jumlah';

  @override
  String get apPgReceiptDone => 'Selesai';

  @override
  String get apPgVaIssued => 'Rekening virtual diterbitkan (rekening uji)';

  @override
  String get apPgTestBadge => 'UJI';

  @override
  String get cIntPayout => 'Pembayaran mitra';

  @override
  String get poTabSettlements => 'Penyelesaian';

  @override
  String get poTabPayouts => 'Pencairan';

  @override
  String get poState_requested => 'Diminta';

  @override
  String get poState_sent => 'Dikirim';

  @override
  String get poState_paid => 'Dibayar';

  @override
  String get poState_failed => 'Gagal';

  @override
  String get poProviderManual => 'Transfer manual';

  @override
  String get poProviderToss => 'Pencairan Toss';

  @override
  String get poShowAccount => 'Tampilkan rekening';

  @override
  String get poAccountTitle => 'Detail transfer';

  @override
  String poAccountBody(
    String holder,
    String bank,
    String account,
    String amount,
  ) {
    return 'Kirim $amount won ke $holder · $bank · $account, lalu tekan konfirmasi.';
  }

  @override
  String get poConfirmPaid => 'Tandai sudah ditransfer';

  @override
  String get poMarkFailed => 'Tandai gagal';

  @override
  String get poReasonTitle => 'Alasan gagal';

  @override
  String get poReasonHint => 'mis. rekening salah, transfer dibatalkan';

  @override
  String get poSend => 'Kirim lewat Toss';

  @override
  String get poSync => 'Cek status';

  @override
  String get poRetry => 'Coba lagi';

  @override
  String get poNoPayouts => 'Belum ada pencairan';

  @override
  String poRequestedToast(String n) {
    return '$n permintaan pencairan dibuat';
  }

  @override
  String get poReasonRequired => 'Masukkan alasan';

  @override
  String get poRevealNote => 'Melihat detail rekening dicatat';

  @override
  String get poSellerAction => 'Daftar penjual';

  @override
  String get poSellerTitle => 'Daftar sebagai penjual Toss';

  @override
  String get poSellerHint =>
      'Memakai rekening pencairan partner yang sudah diverifikasi. Isi data usaha saja.';

  @override
  String get poSellerIndividual => 'Perorangan';

  @override
  String get poSellerCompany => 'Usaha';

  @override
  String get poSellerName => 'Nama';

  @override
  String get poSellerRepresentative => 'Nama perwakilan';

  @override
  String get poSellerRegNo => 'No. registrasi usaha (10 digit)';

  @override
  String get poSellerEmail => 'Email penyelesaian';

  @override
  String get poSellerPhone => 'Telepon';

  @override
  String get poSellerSubmit => 'Daftarkan';

  @override
  String poSellerDone(String status) {
    return 'Status penjual: $status';
  }

  @override
  String get oFlags => 'Sakelar fitur';

  @override
  String get oFlagBooking => 'Pemesanan';

  @override
  String get oFlagChat => 'Chat';

  @override
  String get oFlagAi => 'Asisten AI';

  @override
  String get oFlagPayments => 'Pembayaran';

  @override
  String get oMaintenance => 'Mode pemeliharaan';

  @override
  String get oMaintenanceHint =>
      'Saat aktif, aplikasi pelanggan dan mitra menampilkan layar pemeliharaan. Konsol tetap bisa dipakai.';

  @override
  String get oMaintenanceMessage => 'Pesan pemeliharaan';

  @override
  String get oClientErrors => 'Laporan error aplikasi';

  @override
  String get oClientErrorsHint =>
      'Error terbaru dari web, Windows, dan konsol. Data pribadi disamarkan otomatis.';

  @override
  String get oClientErrorsEmpty => 'Tidak ada error terbaru';

  @override
  String get oHeartbeat => 'Heartbeat uptime';

  @override
  String get oHeartbeatOn =>
      'Terhubung. Layanan luar diberi tahu saat server aktif.';

  @override
  String get oHeartbeatOff =>
      'Belum diatur: tambahkan MALKKEUM_HEARTBEAT_URL ke install.sh.';

  @override
  String get pvManage => 'Pengaturan persetujuan';

  @override
  String get pvOptional => 'Opsional';

  @override
  String get pvTerms => 'Persetujuan Syarat Layanan';

  @override
  String get pvPrivacy => 'Persetujuan pengumpulan dan penggunaan data pribadi';

  @override
  String get pvOverseas => 'Persetujuan transfer data pribadi ke luar negeri';

  @override
  String get pvMarketing => 'Pesan pemasaran';

  @override
  String get pvMarketingHint =>
      'Terima info kupon dan acara lewat SMS, KakaoTalk, dan notifikasi aplikasi. Anda bisa mematikannya kapan saja.';

  @override
  String get pvReconsent =>
      'Kebijakan privasi kami berubah. Silakan tinjau dan setujui lagi.';

  @override
  String get pvSaved => 'Pengaturan persetujuan disimpan';

  @override
  String get pvExport => 'Unduh data saya';

  @override
  String get pvExportHint =>
      'Menampilkan semua data Anda yang kami simpan dalam format JSON. Anda bisa menyalinnya dan menyimpannya.';

  @override
  String get pvCopy => 'Salin';

  @override
  String get pvCopied => 'Tersalin';

  @override
  String get pvExportFailed =>
      'Tidak dapat memuat data Anda. Silakan coba lagi nanti.';

  @override
  String get safetyEmergency => 'Kontak darurat';

  @override
  String get emergencyPolice => '112 Polisi';

  @override
  String get emergencyFire => '119 Pemadam & penyelamatan';

  @override
  String get emergencyShop => 'Layanan pelanggan';

  @override
  String get caseReportAction => 'Laporkan masalah';

  @override
  String get caseReportTitle => 'Apa yang terjadi?';

  @override
  String get caseKindDamage => 'Kerusakan';

  @override
  String get caseKindLoss => 'Kehilangan';

  @override
  String get caseKindComplaint => 'Keluhan';

  @override
  String get caseKindNoShow => 'Pembersih tidak datang';

  @override
  String get caseKindSafety => 'Masalah keselamatan';

  @override
  String get caseKindPayment => 'Sengketa pembayaran';

  @override
  String get caseSummaryHint =>
      'Jelaskan apa yang terjadi (maks. 300 karakter)';

  @override
  String get caseSubmit => 'Kirim';

  @override
  String get caseSubmitted => 'Diterima. Tim kami akan membalas dalam 24 jam.';

  @override
  String get caseFailed => 'Gagal dikirim. Coba lagi.';

  @override
  String get checkInAction => 'Check-in';

  @override
  String get checkOutAction => 'Check-out';

  @override
  String checkedInAt(String time) {
    return 'Tiba $time';
  }

  @override
  String checkedOutAt(String time) {
    return 'Pergi $time';
  }

  @override
  String get entryCodeAction => 'Tampilkan kode masuk';

  @override
  String get entryCodeTitle => 'Kode masuk';

  @override
  String get entryCodeNotToday => 'Hanya bisa dilihat pada hari kunjungan';

  @override
  String get entryCodeEmpty => 'Belum ada kode masuk';

  @override
  String get actionFailed => 'Tidak dapat diselesaikan. Coba lagi.';

  @override
  String get consoleCasesTitle => 'Antrean kasus';

  @override
  String get consoleCasesEmpty => 'Tidak ada kasus terbuka';

  @override
  String get caseOverdue => 'Terlambat';

  @override
  String get caseStatusOpen => 'Baru';

  @override
  String get caseStatusInvestigating => 'Diselidiki';

  @override
  String get caseStatusResolved => 'Selesai';

  @override
  String get caseStatusRejected => 'Ditolak';

  @override
  String get caseReassign => 'Tugaskan ulang mitra';

  @override
  String get caseRefund => 'Pengembalian dana';

  @override
  String get caseHold => 'Tahan penyelesaian';

  @override
  String get caseNoteHint => 'Catatan internal';

  @override
  String get caseSave => 'Simpan';

  @override
  String get cSetup => 'Pengaturan';

  @override
  String get cSetupTitle => 'Siap untuk diluncurkan';

  @override
  String cSetupProgress(String done, String total) {
    return '$done dari $total selesai';
  }

  @override
  String get cSetupAllDone => 'Semua sudah siap!';

  @override
  String get cSetupBusiness => 'Profil bisnis';

  @override
  String get cSetupBusinessName => 'Nama layanan';

  @override
  String get cSetupSupportPhone => 'Telepon dukungan';

  @override
  String get cSetupSupportEmail => 'Email dukungan';

  @override
  String get cSetupSupportHours => 'Jam dukungan';

  @override
  String get cSetupColor => 'Warna merek';

  @override
  String get cSetupLogo => 'Unggah logo';

  @override
  String get cSetupCompany =>
      'Data perusahaan (tampil di bawah aplikasi dan situs)';

  @override
  String get cSetupLegalName => 'Nama resmi';

  @override
  String get cSetupCeo => 'Perwakilan';

  @override
  String get cSetupRegNo => 'Nomor registrasi usaha';

  @override
  String get cSetupMailOrderNo => 'Nomor izin penjualan online';

  @override
  String get cSetupAddress => 'Alamat';

  @override
  String get cSetupPrivacyOfficer => 'Petugas privasi';

  @override
  String get cSetupStoreLinks =>
      'Tautan toko (tombol situs aktif setelah diisi)';

  @override
  String get cSetupCustomerApp => 'Aplikasi pelanggan';

  @override
  String get cSetupPartnerApp => 'Aplikasi mitra';

  @override
  String get cSetupPayMethods => 'Metode pembayaran';

  @override
  String get cSetupPayMethodsHint =>
      'Aktifkan atau matikan metode yang dilihat pelanggan. Berlaku langsung.';

  @override
  String get cReviewTitle => 'Akun demo untuk peninjauan toko';

  @override
  String get cReviewHint =>
      'Peninjau tidak bisa menerima SMS Korea. Tulis nomor dan kode 6 digit di catatan peninjauan. Mati otomatis.';

  @override
  String get cReviewPhone => 'Nomor telepon demo';

  @override
  String get cReviewCode => 'Kode tetap (6 digit)';

  @override
  String cReviewActiveUntil(String date) {
    return 'Aktif sampai $date';
  }

  @override
  String get cReviewEnable => 'Aktifkan (14 hari)';

  @override
  String get pDeleteAccountBody =>
      'Tim dan data pribadi akan dihapus permanen. Selesaikan pekerjaan dan pembayaran tertunda terlebih dulu.';

  @override
  String get err_has_active_jobs =>
      'Masih ada pekerjaan yang ditugaskan. Selesaikan atau minta dukungan memindahkannya.';

  @override
  String get err_pending_payouts =>
      'Masih ada pembayaran tertunda. Akun bisa dihapus setelah dibayar.';

  @override
  String get err_phone_required =>
      'Verifikasi nomor telepon sebelum menerima pekerjaan.';

  @override
  String get nAlerts => 'Notifikasi';

  @override
  String get nEmpty => 'Belum ada notifikasi';

  @override
  String nUnread(String count) {
    return '$count belum dibaca';
  }

  @override
  String get pVerifyPhone => 'Verifikasi';

  @override
  String get mMyJobs => 'Pekerjaan saya';

  @override
  String get mNoJobs =>
      'Belum ada pekerjaan. Pekerjaan dari ketua tim akan muncul di sini.';

  @override
  String mTeam(String team) {
    return 'Anggota $team';
  }

  @override
  String get cSetupSave => 'Simpan';

  @override
  String get cSetupSaved => 'Tersimpan';

  @override
  String get cSetupTest => 'Uji koneksi';

  @override
  String get cSetupClear => 'Putuskan';

  @override
  String get cSetupConnected => 'Terhubung';

  @override
  String get cSetupNotConnected => 'Belum terhubung';

  @override
  String get cSetupFromEnv => 'Memakai pengaturan server';

  @override
  String get cSetupCheckInApp =>
      'Tersimpan · konfirmasi dengan masuk dari aplikasi';

  @override
  String get cSetupInvalidKey => 'Kunci ditolak. Periksa nilai yang disalin';

  @override
  String get cSetupUnreachable =>
      'Layanan tidak dapat dijangkau. Coba lagi nanti';

  @override
  String get cSetupKeepValue => 'Tersimpan (isi hanya untuk mengganti)';

  @override
  String get cSetupGuide => 'Cara mengatur';

  @override
  String get cSetupOpenSite => 'Buka situs';

  @override
  String get cSetupWebhook => 'URL webhook (tempel di konsol PortOne)';

  @override
  String get cCopied => 'Disalin';

  @override
  String get cSetupDevMode =>
      'Mode uji: tidak ada pembayaran atau pesan sungguhan';

  @override
  String get cSetupOptional => 'Opsional';

  @override
  String get cIntPortone => 'Pembayaran (PortOne)';

  @override
  String get cIntSolapi => 'SMS & KakaoTalk (Solapi)';

  @override
  String get cIntPush => 'Notifikasi aplikasi (Firebase)';

  @override
  String get cIntKakao => 'Masuk dengan Kakao';

  @override
  String get cIntNaver => 'Masuk dengan Naver';

  @override
  String get cIntGoogle => 'Masuk dengan Google';

  @override
  String get cIntApple => 'Masuk dengan Apple';

  @override
  String get cFirstRunTitle => 'Selamat datang! Buat akun pemilik';

  @override
  String get cFirstRunBody =>
      'Masukkan kode 12 karakter yang tampil saat instalasi. Akun ini mengelola semua pengaturan.';

  @override
  String get cFirstRunCode => 'Kode instalasi';

  @override
  String get cName => 'Nama';

  @override
  String get cFirstRunCreate => 'Buat akun dan mulai';

  @override
  String get cWrongSetupCode => 'Kode instalasi salah';

  @override
  String get cWeakPassword => 'Kata sandi minimal 12 karakter';

  @override
  String get cInvalidValue => 'Periksa nilai yang diisi';

  @override
  String get cMfaTitle => 'Verifikasi dua langkah';

  @override
  String get cMfaCode => 'Kode 6 digit dari aplikasi autentikator';

  @override
  String get cMfaRecovery => 'Kode pemulihan';

  @override
  String get cMfaUseRecovery => 'Gunakan kode pemulihan';

  @override
  String get cMfaUseCode => 'Gunakan kode autentikator';

  @override
  String get cMfaVerify => 'Verifikasi';

  @override
  String get cMfaBack => 'Kembali ke masuk';

  @override
  String get cMfaEnrolTitle => 'Siapkan verifikasi dua langkah';

  @override
  String get cMfaEnrolBody =>
      'Admin perlu aplikasi autentikator. Tambahkan kunci di bawah ke Google Authenticator, 1Password, atau sejenisnya, lalu masukkan kode 6 digit yang ditampilkan.';

  @override
  String get cMfaSecret => 'Kunci pengaturan';

  @override
  String get cMfaLink => 'Tautan pengaturan (otpauth)';

  @override
  String get cMfaCopy => 'Salin';

  @override
  String get cMfaCopied => 'Disalin';

  @override
  String get cMfaConfirm => 'Konfirmasi dan aktifkan';

  @override
  String get cMfaCodesTitle => 'Simpan kode pemulihan Anda';

  @override
  String get cMfaCodesBody =>
      'Jika kehilangan autentikator, setiap kode bisa dipakai masuk sekali. Kode hanya ditampilkan sekarang.';

  @override
  String get cMfaDownload => 'Unduh';

  @override
  String get cMfaSaveFailed =>
      'Perangkat ini tidak bisa menyimpan file. Salin kode dan simpan dengan aman.';

  @override
  String get cMfaContinue => 'Lanjutkan ke konsol';

  @override
  String get cMfaInvalid =>
      'Kode tidak cocok. Pastikan jam ponsel benar, lalu coba lagi.';

  @override
  String get cMfaExpired =>
      'Masuk sudah kedaluwarsa. Mulai lagi dari langkah kata sandi.';

  @override
  String get cMfaLocked =>
      'Terlalu banyak percobaan. Tunggu beberapa menit lalu coba lagi.';

  @override
  String get cStaffReset => 'Atur ulang kata sandi';

  @override
  String get cStaffResetConfirm =>
      'Atur ulang kata sandi staf ini? Staf akan keluar dari semua perangkat.';

  @override
  String get cStaffResetTitle => 'Token atur ulang';

  @override
  String get cStaffResetBody =>
      'Berikan token ini kepada staf. Hanya bisa dipakai sekali, selama 30 menit. Tidak bisa dilihat lagi setelah ditutup.';

  @override
  String get subTitle => 'Pembersihan rutin';

  @override
  String get subNew => 'Mulai berlangganan';

  @override
  String get subCadence => 'Seberapa sering';

  @override
  String get subWeekly => 'Setiap minggu';

  @override
  String get subBiweekly => 'Setiap 2 minggu';

  @override
  String get subEvery4Weeks => 'Setiap 4 minggu';

  @override
  String get subWeekday => 'Hari';

  @override
  String get subHour => 'Jam kedatangan';

  @override
  String subDiscountNote(String percent) {
    return 'Diskon $percent% untuk setiap kunjungan';
  }

  @override
  String get subChargeNote =>
      'Setiap kunjungan ditagih sehari sebelumnya ke kartu tersimpan';

  @override
  String get subCreate => 'Berlangganan';

  @override
  String get subCreated => 'Langganan dimulai';

  @override
  String get subNeedAddress => 'Tambahkan alamat kunjungan dulu';

  @override
  String get subListEmpty => 'Belum ada langganan';

  @override
  String get subStatusActive => 'Aktif';

  @override
  String get subStatusPaused => 'Dijeda';

  @override
  String get subStatusCancelled => 'Dibatalkan';

  @override
  String subNextVisit(String date) {
    return 'Kunjungan berikutnya $date';
  }

  @override
  String get subPause => 'Jeda';

  @override
  String get subResume => 'Lanjutkan';

  @override
  String get subCancelSub => 'Batalkan langganan';

  @override
  String get subCancelConfirm =>
      'Kunjungan mendatang akan dibatalkan. Kunjungan yang sudah dipesan harus dibatalkan terpisah.';

  @override
  String get subSkip => 'Lewati kunjungan ini';

  @override
  String get subMove => 'Ubah tanggal';

  @override
  String get subVisitLocked =>
      'Tidak bisa diubah mulai sehari sebelum kunjungan';

  @override
  String get subPausedPayment =>
      'Dijeda karena pembayaran gagal berulang kali. Ganti kartu lalu lanjutkan.';

  @override
  String get subStatePlanned => 'Terjadwal';

  @override
  String get subStateBooked => 'Dipesan';

  @override
  String get subStateSkipped => 'Dilewati';

  @override
  String get subStateMissed => 'Terlewat';

  @override
  String get pSubsTitle => 'Pelanggan rutin';

  @override
  String get pSubsEmpty => 'Belum ada pelanggan rutin';

  @override
  String get cSubsTitle => 'Langganan';

  @override
  String get cSubsEdit => 'Ubah untuk pelanggan';

  @override
  String get cMrr => 'Pendapatan berulang bulanan (MRR)';

  @override
  String get cChurn => 'Churn';

  @override
  String get cActiveSubs => 'Langganan aktif';

  @override
  String get cRecognized => 'Pendapatan diakui periode ini';

  @override
  String get cSubsLoadFailed => 'Langganan tidak dapat dimuat';

  @override
  String get tTaxSection => 'Pajak';

  @override
  String tVatQuarter(String q) {
    return 'CSV PPN K$q';
  }

  @override
  String get tVatYear => 'Tahun';

  @override
  String get tExportWithholding => 'CSV bukti potong';

  @override
  String get tExportTaxInvoices => 'CSV unggah faktur pajak';

  @override
  String get tTaxLayoutNote =>
      'Periksa kolom dengan template 홈택스 asli sebelum mengunggah. Tata letak belum diverifikasi.';

  @override
  String get tCashReceipts => 'Kuitansi tunai';

  @override
  String get tCashIssued => 'Diterbitkan';

  @override
  String get tCashFailed => 'Gagal';

  @override
  String get tCashPending => 'Menunggu';

  @override
  String get tCashCancelled => 'Dibatalkan';

  @override
  String get tReissue => 'Terbitkan ulang';

  @override
  String get tTaxInvoices => 'Faktur pajak';

  @override
  String get tApprovalNumber => 'No. persetujuan';

  @override
  String get tIssuedOn => 'Tanggal terbit';

  @override
  String get tMarkIssued => 'Tandai sudah diterbitkan';

  @override
  String get tQueueEmpty => 'Tidak ada permintaan menunggu';

  @override
  String get tWithholdingLabel => 'Pemotongan pajak';

  @override
  String get tGrossAmount => 'Bruto';

  @override
  String get tIncomeTax => 'PPh';

  @override
  String get tLocalTax => 'PPh daerah';

  @override
  String get tNetAmount => 'Bersih';

  @override
  String get tNoWithholding => 'Tanpa pemotongan (usaha terdaftar)';

  @override
  String get tEstWithholding => 'Perkiraan pemotongan (belum dibayar)';

  @override
  String get tReceiptOptions => 'Opsi kuitansi';

  @override
  String get tWantCashReceipt => 'Minta kuitansi tunai';

  @override
  String get tCashForIncome => 'Untuk pengurangan pajak (nomor telepon)';

  @override
  String get tCashForBusiness => 'Untuk biaya usaha (no. usaha)';

  @override
  String get tWantTaxInvoice => 'Minta faktur pajak (usaha)';

  @override
  String get tPhoneForReceipt => 'Nomor telepon';

  @override
  String get tBusinessNumber => 'No. registrasi usaha';

  @override
  String get tCompanyName => 'Nama perusahaan';

  @override
  String get tRepresentative => 'Perwakilan';

  @override
  String get tInvoiceEmail => 'Email untuk faktur';

  @override
  String get tReceiptSave => 'Simpan dan bayar';

  @override
  String get tReceiptSaveFailed => 'Detail kuitansi tidak tersimpan';

  @override
  String get tTaxType => 'Jenis pajak';

  @override
  String get tTaxFreelancer => 'Freelancer (dipotong pajak)';

  @override
  String get tTaxBusiness => 'Usaha terdaftar (tanpa pemotongan)';

  @override
  String get tReceiptSettings => 'Pengaturan kuitansi';

  @override
  String get reviewRuleLine =>
      'Dilarang ujaran kebencian, informasi pribadi, konten palsu atau promosi. Ulasan yang dilaporkan akan disembunyikan.';

  @override
  String get reportAction => 'Laporkan';

  @override
  String get reportSheetTitle => 'Laporkan ulasan ini?';

  @override
  String get reportReasonSpam => 'Spam atau iklan';

  @override
  String get reportReasonOffensive => 'Hinaan atau kebencian';

  @override
  String get reportReasonPersonal => 'Berisi informasi pribadi';

  @override
  String get reportReasonOther => 'Lainnya';

  @override
  String get reportNoteHint => 'Detail (opsional, maks. 300 karakter)';

  @override
  String get reportSubmit => 'Kirim laporan';

  @override
  String get reportThanks => 'Terima kasih. Tim kami akan meninjaunya.';

  @override
  String get reportAlready => 'Anda sudah melaporkan ulasan ini';

  @override
  String get reportFailed => 'Laporan gagal dikirim. Coba lagi.';

  @override
  String get reviewBlocked =>
      'Akun ini tidak dapat memberi ulasan. Hubungi dukungan.';

  @override
  String get modTitle => 'Ulasan yang dilaporkan';

  @override
  String get modEmpty => 'Tidak ada laporan yang menunggu';

  @override
  String modReports(String count) {
    return '$count laporan';
  }

  @override
  String get modKeep => 'Pertahankan';

  @override
  String get modHide => 'Sembunyikan';

  @override
  String get modDelete => 'Hapus';

  @override
  String get modBlockAuthor => 'Batasi penulis';

  @override
  String get modUnblockAuthor => 'Cabut pembatasan';

  @override
  String get modDone => 'Selesai';

  @override
  String get modFailed => 'Tidak dapat diproses. Coba lagi.';

  @override
  String get modHidden => 'Ulasan tersembunyi';

  @override
  String uUpdateBanner(String version) {
    return 'Versi baru $version tersedia';
  }

  @override
  String get uUpdateNow => 'Perbarui';

  @override
  String get uUpdateLater => 'Nanti';

  @override
  String get uUpdateRequiredTitle => 'Pembaruan diperlukan';

  @override
  String get uUpdateRequiredBody =>
      'Versi ini sudah tidak didukung. Silakan perbarui dari toko aplikasi.';

  @override
  String get uUpdateStore => 'Perbarui di toko';

  @override
  String get uUpdateStoreMissing =>
      'Tautan pembaruan belum siap. Coba lagi nanti.';

  @override
  String uCurrentVersion(String version) {
    return 'Versi saat ini $version';
  }

  @override
  String get uAppVersionTitle => 'Versi aplikasi';

  @override
  String get uAppVersionHint =>
      'Aplikasi di bawah versi minimum akan berhenti di layar pembaruan. Versi di bawah yang terbaru akan melihat banner. Contoh: 1.2.0';

  @override
  String get uMinVersion => 'Versi minimum';

  @override
  String get uLatestVersion => 'Versi terbaru';

  @override
  String get walletTitle => 'Dompet poin';

  @override
  String get walletBalance => 'Poin tersedia';

  @override
  String walletPoints(String count) {
    return '$count P';
  }

  @override
  String walletExpiring(String days, String count) {
    return '$count P akan hangus dalam $days hari';
  }

  @override
  String get walletOff => 'Program poin belum dibuka';

  @override
  String get walletEmpty => 'Belum ada aktivitas poin';

  @override
  String get walletHistory => 'Aktivitas terbaru';

  @override
  String get walletKindEarn => 'Cashback pemesanan';

  @override
  String get walletKindWelcome => 'Poin selamat datang';

  @override
  String get walletKindReferral => 'Hadiah rujukan';

  @override
  String get walletKindRefund => 'Poin dikembalikan';

  @override
  String get walletKindSpend => 'Dipakai untuk pemesanan';

  @override
  String get walletKindExpire => 'Hangus';

  @override
  String get walletKindOther => 'Penyesuaian poin';

  @override
  String get moreWallet => 'Dompet poin';

  @override
  String get payHistoryTitle => 'Riwayat pembayaran';

  @override
  String get payHistoryEmpty => 'Belum ada pembayaran';

  @override
  String get payStatusPaid => 'Lunas';

  @override
  String get payStatusRefunded => 'Sudah dikembalikan';

  @override
  String get payStatusPending => 'Menunggu pembayaran';

  @override
  String get payStatusClosed => 'Belum dibayar';

  @override
  String get receiptTitle => 'Struk elektronik';

  @override
  String get receiptLegal => 'Nama usaha';

  @override
  String get receiptRegNo => 'No. registrasi usaha';

  @override
  String get receiptAddr => 'Alamat';

  @override
  String get receiptPhone => 'Layanan pelanggan';

  @override
  String get receiptDate => 'Tanggal bayar';

  @override
  String get receiptCopy => 'Salin struk';

  @override
  String get receiptCopied => 'Struk disalin';

  @override
  String get receiptNote =>
      'Hanya bukti pembayaran. Untuk faktur pajak, ajukan dari detail pemesanan.';

  @override
  String get checkoutPointsUse => 'Gunakan poin';

  @override
  String checkoutPointsAvail(String count, String max) {
    return '$count P tersedia · maksimal $max P untuk pembayaran ini';
  }

  @override
  String get checkoutPointsNeedsWindow =>
      'Poin bisa dipakai saat membayar lewat jendela pembayaran';

  @override
  String get pointsLedgerTitle => 'Buku besar poin';

  @override
  String get pointsAdjustAmount => 'Poin (negatif untuk mengurangi)';

  @override
  String get pointsAdjustReason => 'Alasan penyesuaian';

  @override
  String get pointsAdjustInvalid => 'Masukkan poin bukan nol dan alasannya';

  @override
  String get pointsAdjustDone => 'Poin disesuaikan';

  @override
  String get err_points_insufficient =>
      'Poin Anda tidak cukup. Kurangi poin yang dipakai.';

  @override
  String get err_points_over_cap => 'Melebihi batas poin untuk pembayaran ini.';

  @override
  String get err_points_cover_total =>
      'Poin tidak bisa membayar seluruh jumlah. Kurangi sedikit.';

  @override
  String get webBookNow => 'Pesan lewat web';

  @override
  String get webBookSub => 'Tanpa perlu memasang aplikasi';

  @override
  String get apPgBrowserNote =>
      'Selesaikan pembayaran di browser, lalu kembali ke sini dan tekan tombol di bawah.';

  @override
  String get apPgBrowserDone => 'Saya sudah membayar';
}
