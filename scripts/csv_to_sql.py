#!/usr/bin/env python3
"""
CSV to SQL Generator for Card Gorilla Data
Converts card_gorilla_list.csv to SQL INSERT statements for cards and card_benefits tables.
"""

import csv
import re
import sys
from pathlib import Path

# Category mapping: keywords to category variable names
# Based on the 14 categories already seeded in the database
CATEGORY_MAP = {
    '식비': '@cat_food',
    '카페/디저트': '@cat_cafe',
    '대중교통': '@cat_transport',
    '편의점': '@cat_conv',
    '온라인쇼핑': '@cat_online',
    '대형마트': '@cat_mart',
    '주유/차량': '@cat_gas',
    '통신/공과금': '@cat_bill',
    '디지털구독': '@cat_digital',
    '문화/여가': '@cat_culture',
    '의료/건강': '@cat_health',
    '교육': '@cat_edu',
    '뷰티/잡화': '@cat_beauty',
    '여행/숙박': '@cat_travel',
}

# Keyword to category mapping
KEYWORD_TO_CATEGORY = {
    # 식비
    '식음료': '식비', '식비': '식비', '음식점': '식비', '외식': '식비',
    '일반음식점': '식비', '식당': '식비', '레스토랑': '식비',

    # 카페/디저트
    '카페': '카페/디저트', '디저트': '카페/디저트', '커피': '카페/디저트',
    '스타벅스': '카페/디저트', '베이커리': '카페/디저트',

    # 대중교통
    '교통': '대중교통', '대중교통': '대중교통', '택시': '대중교통',
    '버스': '대중교통', '지하철': '대중교통', '전철': '대중교통',

    # 편의점
    '편의점': '편의점', 'CVS': '편의점', 'GS25': '편의점', 'CU': '편의점',
    '세븐일레븐': '편의점',

    # 온라인쇼핑
    '온라인': '온라인쇼핑', '쇼핑': '온라인쇼핑', '인터넷': '온라인쇼핑',
    '온라인쇼핑': '온라인쇼핑', '쿠팡': '온라인쇼핑', '배달': '온라인쇼핑',
    '배달앱': '온라인쇼핑', '간편결제': '온라인쇼핑',

    # 대형마트
    '마트': '대형마트', '대형마트': '대형마트', '슈퍼마켓': '대형마트',
    '백화점': '대형마트', '대형할인점': '대형마트', '이마트': '대형마트',
    '홈플러스': '대형마트', '롯데마트': '대형마트',

    # 주유/차량
    '주유': '주유/차량', '차량': '주유/차량', '자동차': '주유/차량',
    '정유사': '주유/차량', '차량서비스': '주유/차량', '주차': '주유/차량',

    # 통신/공과금
    '통신': '통신/공과금', '공과금': '통신/공과금', 'SKT': '통신/공과금',
    'KT': '통신/공과금', 'LG': '통신/공과금', '통신요금': '통신/공과금',
    '관리비': '통신/공과금', '아파트관리비': '통신/공과금',

    # 디지털구독
    '디지털': '디지털구독', '구독': '디지털구독', 'OTT': '디지털구독',
    '넷플릭스': '디지털구독', '스포티파이': '디지털구독', '스트리밍': '디지털구독',
    '디지털콘텐츠': '디지털구독', '멤버십': '디지털구독', '인앱': '디지털구독',

    # 문화/여가
    '문화': '문화/여가', '영화': '문화/여가', '공연': '문화/여가',
    'CGV': '문화/여가', '롯데시네마': '문화/여가', '메가박스': '문화/여가',
    '여가': '문화/여가',

    # 의료/건강
    '의료': '의료/건강', '건강': '의료/건강', '병원': '의료/건강',
    '약국': '의료/건강',

    # 교육
    '교육': '교육', '학원': '교육', '도서': '교육', '서점': '교육',

    # 뷰티/잡화
    '뷰티': '뷰티/잡화', '화장품': '뷰티/잡화', '올리브영': '뷰티/잡화',
    '패션': '뷰티/잡화', '의류': '뷰티/잡화',

    # 여행/숙박
    '여행': '여행/숙박', '숙박': '여행/숙박', '항공': '여행/숙박',
    '호텔': '여행/숙박', '면세': '여행/숙박', '면세점': '여행/숙박',
    '공항': '여행/숙박', '라운지': '여행/숙박', '골프': '여행/숙박',
}

# Keywords to skip (not actual spending categories)
SKIP_KEYWORDS = {
    '마일', '마일리지', '적립', '포인트', '캐시백', '서비스',
    '무료', '할인', '혜택', '선택', '기프트', '바우처', 'MR',
}


def parse_annual_fee(fee_text):
    """
    Parse annual fee text to extract domestic and overseas fees.

    Examples:
    - "국내전용 20,000 원 / 해외겸용 20,000 원" -> (20000, 20000)
    - "해외겸용 15,000 원" -> (0, 15000)
    - "국내전용 없음 / 해외겸용 없음" -> (0, 0)
    - "없음" or "연회비 없음" -> (0, 0)
    """
    if not fee_text or '없음' in fee_text:
        return 0, 0

    domestic = 0
    overseas = 0

    # Extract domestic fee
    domestic_match = re.search(r'국내전용\s*([\d,]+)\s*원', fee_text)
    if domestic_match:
        domestic = int(domestic_match.group(1).replace(',', ''))

    # Extract overseas fee
    overseas_match = re.search(r'해외겸용\s*([\d,]+)\s*원', fee_text)
    if overseas_match:
        overseas = int(overseas_match.group(1).replace(',', ''))

    return domestic, overseas


def extract_category_keyword(benefit_text):
    """
    Extract category keyword from benefit text.
    Returns the first matched category name.
    """
    benefit_lower = benefit_text.lower()

    # Check skip keywords first
    for skip_word in SKIP_KEYWORDS:
        if skip_word in benefit_lower:
            return None

    # Try to match keywords
    for keyword, category_name in KEYWORD_TO_CATEGORY.items():
        if keyword.lower() in benefit_lower or keyword in benefit_text:
            return category_name

    return None


def parse_benefit_rate(benefit_text):
    """
    Extract percentage from benefit text.

    Examples:
    - "10%할인" -> 10.0
    - "5%적립" -> 5.0
    - "1.5%할인" -> 1.5
    """
    # Match patterns like "10%", "1.5%"
    match = re.search(r'([\d.]+)\s*%', benefit_text)
    if match:
        return float(match.group(1))
    return None


def parse_benefits(benefits_text):
    """
    Parse benefits text and return list of (category_variable, benefit_rate) tuples.

    Example input: "공과금: 10%할인 | 마트,편의점: 10%할인 | 식음료: 10%할인"
    Returns: [('@cat_bill', 10.0), ('@cat_mart', 10.0), ('@cat_conv', 10.0), ('@cat_food', 10.0)]
    """
    if not benefits_text or benefits_text.strip() == '':
        return []

    benefits = []

    # Split by "|" to get individual benefit entries
    parts = benefits_text.split('|')

    for part in parts:
        part = part.strip()
        if not part or ':' not in part:
            continue

        # Split into category keywords and benefit description
        category_part, benefit_part = part.split(':', 1)
        category_keywords = category_part.strip()
        benefit_description = benefit_part.strip()

        # Extract percentage
        rate = parse_benefit_rate(benefit_description)
        if rate is None:
            continue

        # Extract categories from keywords (may be comma-separated like "마트,편의점")
        keyword_list = [k.strip() for k in category_keywords.split(',')]

        for keyword in keyword_list:
            category_name = extract_category_keyword(keyword)
            if category_name and category_name in CATEGORY_MAP:
                category_var = CATEGORY_MAP[category_name]
                benefits.append((category_var, rate))

    return benefits


def escape_sql_string(text):
    """Escape single quotes in SQL strings."""
    if text is None:
        return 'NULL'
    return "'" + text.replace("'", "''").replace('\\', '\\\\') + "'"


def generate_sql(csv_path, max_cards=100):
    """
    Generate SQL INSERT statements from CSV file.
    """
    csv_path = Path(csv_path)
    if not csv_path.exists():
        print(f"Error: CSV file not found: {csv_path}", file=sys.stderr)
        sys.exit(1)

    cards_processed = 0
    cards_skipped = 0
    total_benefits = 0

    print("-- Generated SQL for card_gorilla_list.csv")
    print("-- Cards and card_benefits INSERT statements")
    print("-- Compatible with seed_mock_data.sql format")
    print()
    print("SET NAMES utf8mb4;")
    print("SET @NOW = NOW();")
    print()
    print("-- -------------------------------------------------------------")
    print("-- Real Cards from Card Gorilla CSV")
    print("-- -------------------------------------------------------------")
    print()

    card_counter = 1

    try:
        # Try different encodings
        for encoding in ['utf-8-sig', 'utf-8', 'cp949']:
            try:
                with open(csv_path, 'r', encoding=encoding) as f:
                    reader = csv.DictReader(f)

                    for row in reader:
                        if cards_processed >= max_cards:
                            break

                        try:
                            card_name = row['카드명'].strip()
                            company = row['카드사'].strip()
                            annual_fee = row['연회비'].strip()
                            baseline_req = row['전월실적'].strip()
                            benefits = row['주요혜택'].strip()
                            promotion = row['프로모션'].strip()
                            detail_url = row['상세링크'].strip()
                            image_url = row['이미지URL'].strip()

                            # Parse annual fees
                            domestic_fee, overseas_fee = parse_annual_fee(annual_fee)

                            # Generate card INSERT
                            print(f"-- Card {card_counter}: {card_name}")
                            print(f"INSERT INTO cards (card_name, company, card_image_url, "
                                  f"annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, "
                                  f"benefit_cap_summary, created_at, updated_at)")
                            print(f"VALUES ({escape_sql_string(card_name)}, {escape_sql_string(company)}, "
                                  f"{escape_sql_string(image_url)}, {domestic_fee}, {overseas_fee}, "
                                  f"{escape_sql_string(baseline_req)}, {escape_sql_string(promotion)}, "
                                  f"@NOW, @NOW);")
                            print(f"SET @card{card_counter} = LAST_INSERT_ID();")
                            print()

                            # Parse and generate benefit INSERTs
                            benefit_list = parse_benefits(benefits)
                            if benefit_list:
                                for category_var, rate in benefit_list:
                                    print(f"INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)")
                                    print(f"VALUES ({rate:.2f}, NULL, @NOW, @NOW, @card{card_counter}, {category_var});")
                                    total_benefits += 1
                                print()

                            card_counter += 1
                            cards_processed += 1

                        except Exception as e:
                            cards_skipped += 1
                            print(f"-- ERROR: Skipped card due to parsing error: {e}", file=sys.stderr)
                            continue

                # If we successfully read the file, break
                break

            except UnicodeDecodeError:
                continue

    except Exception as e:
        print(f"Error reading CSV: {e}", file=sys.stderr)
        sys.exit(1)

    # Print summary
    print()
    print(f"-- Summary:")
    print(f"-- Total cards processed: {cards_processed}")
    print(f"-- Total cards skipped: {cards_skipped}")
    print(f"-- Total benefits generated: {total_benefits}")
    print(f"-- Average benefits per card: {total_benefits / cards_processed if cards_processed > 0 else 0:.2f}")


if __name__ == '__main__':
    csv_path = '/Users/leesanghun/My_Project/Team_Project/BootCamp-F/Backend/Backend/card_gorilla_list.csv'

    # Allow command line override
    if len(sys.argv) > 1:
        csv_path = sys.argv[1]

    # Process first 50 cards as requested
    generate_sql(csv_path, max_cards=50)
