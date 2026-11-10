// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class TId extends T {
  TId([String locale = 'id']) : super(locale);

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
  String get apMethodVirtual => 'Virtual account';

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
  String get cStatus => 'Status';

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
  String get f_duplex => 'Duplex';

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
  String get cKind_banner => 'Banner';

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
  String get cRating => 'Rating';

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
  String get cRoleAdmin => 'Admin';

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
  String get ok => 'OK';

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
      'Dalam 2 hari sebelum kunjungan, batalkan lewat tim kami';

  @override
  String get err_address_required => 'Tambahkan alamat kunjungan';

  @override
  String get err_already_taken => 'Mitra lain sudah menerimanya lebih dulu';

  @override
  String get err_invalid_address => 'Isi semua kolom alamat';

  @override
  String get tabHome => 'Beranda';

  @override
  String get tabBookings => 'Pemesanan';

  @override
  String get tabChat => 'Chat';

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
  String get addressLabel => 'Label';

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
  String get deposit => 'Deposit';

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
  String get chatTitle => 'Chat';

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
  String get moreFaq => 'FAQ';

  @override
  String get morePartner => 'Jadi mitra';

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
  String get webBookNow => 'Pesan lewat web';

  @override
  String get webBookSub => 'Tanpa perlu memasang aplikasi';
}
