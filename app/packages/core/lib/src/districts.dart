/// Service area (decision #8): Seoul's 25 districts with official 5-digit codes.
/// Add rows to open new areas; partners filter jobs by these codes.
class District {
  const District(this.code, this.ko, this.en);
  final String code;
  final String ko;
  final String en;
  String name(String lang) => lang == 'ko' ? ko : en;
}

const seoulDistricts = [
  District('11680', '강남구', 'Gangnam-gu'),
  District('11650', '서초구', 'Seocho-gu'),
  District('11710', '송파구', 'Songpa-gu'),
  District('11740', '강동구', 'Gangdong-gu'),
  District('11440', '마포구', 'Mapo-gu'),
  District('11560', '영등포구', 'Yeongdeungpo-gu'),
  District('11170', '용산구', 'Yongsan-gu'),
  District('11200', '성동구', 'Seongdong-gu'),
  District('11215', '광진구', 'Gwangjin-gu'),
  District('11590', '동작구', 'Dongjak-gu'),
  District('11620', '관악구', 'Gwanak-gu'),
  District('11500', '강서구', 'Gangseo-gu'),
  District('11470', '양천구', 'Yangcheon-gu'),
  District('11530', '구로구', 'Guro-gu'),
  District('11545', '금천구', 'Geumcheon-gu'),
  District('11410', '서대문구', 'Seodaemun-gu'),
  District('11380', '은평구', 'Eunpyeong-gu'),
  District('11110', '종로구', 'Jongno-gu'),
  District('11140', '중구', 'Jung-gu'),
  District('11230', '동대문구', 'Dongdaemun-gu'),
  District('11260', '중랑구', 'Jungnang-gu'),
  District('11290', '성북구', 'Seongbuk-gu'),
  District('11305', '강북구', 'Gangbuk-gu'),
  District('11320', '도봉구', 'Dobong-gu'),
  District('11350', '노원구', 'Nowon-gu'),
];

District? districtByCode(String code) {
  for (final d in seoulDistricts) {
    if (d.code == code) return d;
  }
  return null;
}
