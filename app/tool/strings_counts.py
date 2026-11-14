# Counts services (CR-5 aircon/sofa/mattress steppers, CR-6 disinfection cards, window counts):
# option names, short labels for summaries ("벽걸이 1 · 스탠드 2"), counts-screen hints. One row per key.
# Columns: ko (source), en. S below is derived for gen_arb.py.
COLS = ["ko", "en"]

ROWS = {
  "svc_window": ["창문 청소", "Window cleaning"],
  "svc_disinfection": ["방역·소독", "Pest control & disinfection"],
  "svcDesc_window": ["창문 안팎을 창 크기별 개수대로 청소해요", "Inside and outside of windows, priced per window size"],
  "svcDesc_disinfection": ["필요한 방역과 소독을 골라 주세요", "Choose the pest control and disinfection you need"],
  "unitTitle_window": ["창문 크기와 개수를\n골라 주세요.", "Choose window sizes\nand counts."],
  "unitTitle_disinfection": ["방역 종류를\n골라 주세요.", "Choose the\ntreatments."],
  "unit_window_small": ["작은 창 (1m 미만)", "Small window (under 1m)"],
  "unit_window_large": ["큰 창 (1m 이상)", "Large window (1m and over)"],
  "unit_pest": ["해충 방역", "Pest control"],
  "unit_mite_bedbug": ["진드기·빈대 퇴치", "Mite & bed bug treatment"],
  "unit_sanitize": ["살균·바이러스 소독", "Sanitising & virus disinfection"],
  "unit_sick_house": ["새집증후군 제거", "New-home syndrome removal"],
  "unitShort_wall": ["벽걸이", "Wall"],
  "unitShort_stand": ["스탠드", "Stand"],
  "unitShort_two_in_one": ["2in1", "2-in-1"],
  "unitShort_ceiling": ["천장형", "Ceiling"],
  "unitShort_seat_1_2": ["1~2인용", "1–2 seats"],
  "unitShort_seat_3": ["3인용", "3 seats"],
  "unitShort_seat_4_plus": ["4인용 이상", "4+ seats"],
  "unitShort_l_shape": ["L자", "L-shape"],
  "unitShort_small": ["작은 창", "Small window"],
  "unitShort_large": ["큰 창", "Large window"],
  "unitShort_pest": ["해충 방역", "Pest control"],
  "unitShort_mite_bedbug": ["진드기·빈대", "Mites & bed bugs"],
  "unitShort_sanitize": ["살균·소독", "Sanitising"],
  "unitShort_sick_house": ["새집증후군", "New-home syndrome"],
  "unitHint": ["필요한 만큼 +, −로 골라 주세요", "Use + and − to choose what you need"],
  "countsDiscount": ["{percent}% 할인 적용 (2개 이상 선택)", "{percent}% off for 2 or more"],
  "countMinus": ["개수 줄이기", "Decrease count"],
  "countPlus": ["개수 늘리기", "Increase count"],
  "countSelect": ["선택", "Select"],
  "svcNotes_disinfection": ["가격은 약 30평 기준이에요\n더 넓은 집은 채팅에서 금액을 조정해 드려요", "Prices assume about 30 pyeong\nLarger homes are adjusted in chat"],
}

for _k, _row in ROWS.items():
    assert len(_row) == len(COLS), _k

S = ROWS
