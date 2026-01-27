-- =============================================================
-- Mock Data Seed Script (확장판)
-- 테스트용 사용자 3명 + 카드 3종 + 카테고리 + 6개월치 지출 데이터
-- 사용법: docker exec -i mysqldb mysql -u root -proot --default-character-set=utf8mb4 card_recommend_db < scripts/seed_mock_data.sql
-- =============================================================

SET NAMES utf8mb4;
SET @NOW = NOW();

-- -------------------------------------------------------------
-- 1. 카테고리 (14종, CATEGORY_MAPPING 기준)
-- -------------------------------------------------------------
INSERT IGNORE INTO category (category_name, created_at, updated_at)
VALUES
  ('식비',         @NOW, @NOW),
  ('카페/디저트',  @NOW, @NOW),
  ('대중교통',     @NOW, @NOW),
  ('편의점',       @NOW, @NOW),
  ('온라인쇼핑',   @NOW, @NOW),
  ('대형마트',     @NOW, @NOW),
  ('주유/차량',    @NOW, @NOW),
  ('통신/공과금',  @NOW, @NOW),
  ('디지털구독',   @NOW, @NOW),
  ('문화/여가',    @NOW, @NOW),
  ('의료/건강',    @NOW, @NOW),
  ('교육',         @NOW, @NOW),
  ('뷰티/잡화',   @NOW, @NOW),
  ('여행/숙박',   @NOW, @NOW);

-- 카테고리 ID 캐싱
SET @cat_food      = (SELECT category_id FROM category WHERE category_name = '식비' LIMIT 1);
SET @cat_cafe      = (SELECT category_id FROM category WHERE category_name = '카페/디저트' LIMIT 1);
SET @cat_transport = (SELECT category_id FROM category WHERE category_name = '대중교통' LIMIT 1);
SET @cat_conv      = (SELECT category_id FROM category WHERE category_name = '편의점' LIMIT 1);
SET @cat_online    = (SELECT category_id FROM category WHERE category_name = '온라인쇼핑' LIMIT 1);
SET @cat_mart      = (SELECT category_id FROM category WHERE category_name = '대형마트' LIMIT 1);
SET @cat_gas       = (SELECT category_id FROM category WHERE category_name = '주유/차량' LIMIT 1);
SET @cat_bill      = (SELECT category_id FROM category WHERE category_name = '통신/공과금' LIMIT 1);
SET @cat_digital   = (SELECT category_id FROM category WHERE category_name = '디지털구독' LIMIT 1);
SET @cat_culture   = (SELECT category_id FROM category WHERE category_name = '문화/여가' LIMIT 1);
SET @cat_health    = (SELECT category_id FROM category WHERE category_name = '의료/건강' LIMIT 1);
SET @cat_edu       = (SELECT category_id FROM category WHERE category_name = '교육' LIMIT 1);
SET @cat_beauty    = (SELECT category_id FROM category WHERE category_name = '뷰티/잡화' LIMIT 1);
SET @cat_travel    = (SELECT category_id FROM category WHERE category_name = '여행/숙박' LIMIT 1);

-- -------------------------------------------------------------
-- 2. 테스트 사용자 3명
-- -------------------------------------------------------------
INSERT INTO users (email, password, name, age_group, gender, created_at, updated_at, is_active, phone, birth_date)
VALUES ('mockuser@test.com', 'mock1234*', '한정수', '20대', 0, @NOW, @NOW, 1, '01011112222', '19990301');
SET @uid1 = LAST_INSERT_ID();

INSERT INTO users (email, password, name, age_group, gender, created_at, updated_at, is_active, phone, birth_date)
VALUES ('testuser2@test.com', 'test1234*', '김테스트', '30대', 1, @NOW, @NOW, 1, '01033334444', '19920515');
SET @uid2 = LAST_INSERT_ID();

INSERT INTO users (email, password, name, age_group, gender, created_at, updated_at, is_active, phone, birth_date)
VALUES ('testuser3@test.com', 'test1234*', '박샘플', '20대', 0, @NOW, @NOW, 1, '01055556666', '19970820');
SET @uid3 = LAST_INSERT_ID();

-- -------------------------------------------------------------
-- 3. 카드 3종 + 유저카드 4건
-- -------------------------------------------------------------
INSERT INTO cards (card_name, company, annual_fee_domestic, annual_fee_overseas, created_at, updated_at)
VALUES ('테스트 신한카드', '신한카드', 0, 0, @NOW, @NOW);
SET @card1 = LAST_INSERT_ID();

INSERT INTO cards (card_name, company, annual_fee_domestic, annual_fee_overseas, created_at, updated_at)
VALUES ('테스트 삼성카드', '삼성카드', 10000, 5000, @NOW, @NOW);
SET @card2 = LAST_INSERT_ID();

INSERT INTO cards (card_name, company, annual_fee_domestic, annual_fee_overseas, created_at, updated_at)
VALUES ('테스트 현대카드', '현대카드', 15000, 10000, @NOW, @NOW);
SET @card3 = LAST_INSERT_ID();

-- User1 -> Card1, Card2 / User2 -> Card2 / User3 -> Card3
INSERT INTO user_cards (registered_at, created_at, updated_at, card_id, user_id, card_number)
VALUES (@NOW, @NOW, @NOW, @card1, @uid1, '123456******7890');
SET @ucid1 = LAST_INSERT_ID();

INSERT INTO user_cards (registered_at, created_at, updated_at, card_id, user_id, card_number)
VALUES (@NOW, @NOW, @NOW, @card2, @uid1, '987654******3210');
SET @ucid2 = LAST_INSERT_ID();

INSERT INTO user_cards (registered_at, created_at, updated_at, card_id, user_id, card_number)
VALUES (@NOW, @NOW, @NOW, @card2, @uid2, '555666******1234');
SET @ucid3 = LAST_INSERT_ID();

INSERT INTO user_cards (registered_at, created_at, updated_at, card_id, user_id, card_number)
VALUES (@NOW, @NOW, @NOW, @card3, @uid3, '111222******5678');
SET @ucid4 = LAST_INSERT_ID();

-- -------------------------------------------------------------
-- 4. 카드 혜택 (card_benefits)
-- -------------------------------------------------------------
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES
  -- 신한카드
  (5.00, 10000, @NOW, @NOW, @card1, @cat_food),
  (3.00,  5000, @NOW, @NOW, @card1, @cat_cafe),
  (10.00, 5000, @NOW, @NOW, @card1, @cat_transport),
  (2.00,  8000, @NOW, @NOW, @card1, @cat_online),
  (3.00, 10000, @NOW, @NOW, @card1, @cat_mart),
  -- 삼성카드
  (3.00,  8000, @NOW, @NOW, @card2, @cat_food),
  (5.00, 15000, @NOW, @NOW, @card2, @cat_online),
  (10.00, 5000, @NOW, @NOW, @card2, @cat_digital),
  (5.00,  8000, @NOW, @NOW, @card2, @cat_culture),
  (5.00, 10000, @NOW, @NOW, @card2, @cat_gas),
  -- 현대카드
  (10.00, 8000, @NOW, @NOW, @card3, @cat_cafe),
  (5.00,  3000, @NOW, @NOW, @card3, @cat_conv),
  (5.00, 12000, @NOW, @NOW, @card3, @cat_mart),
  (7.00, 10000, @NOW, @NOW, @card3, @cat_beauty),
  (3.00, 20000, @NOW, @NOW, @card3, @cat_travel);

-- =============================================================
-- 5. 지출 데이터 — User1 (한정수) : 6개월 (2025-08 ~ 2026-01)
--    주력: 식비/카페 + 온라인쇼핑, Card1(신한) 주력, Card2(삼성) 보조
-- =============================================================

-- ── 2025년 8월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (8500,  '김밥천국 강남점',     '2025-08-01 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (4500,  '스타벅스 테헤란로',   '2025-08-02 09:10:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-08-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (12000, '맘스터치 선릉점',     '2025-08-04 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (1350,  'CU 역삼역점',         '2025-08-04 18:20:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (25000, '쿠팡',               '2025-08-06 21:30:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (7900,  '본죽 역삼점',         '2025-08-07 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (55000, 'SK텔레콤',           '2025-08-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid1, @ucid1, 0,0,0,0,0),
  (5500,  '투썸플레이스',         '2025-08-10 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-08-11 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (9500,  '한솥도시락 선릉점',   '2025-08-13 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (15000, 'CGV 강남',           '2025-08-14 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid1, @ucid1, 0,0,0,0,0),
  (3200,  'GS25 선릉점',         '2025-08-15 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (11000, '서브웨이 역삼점',     '2025-08-17 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (48000, 'GS칼텍스 강남주유소', '2025-08-18 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-08-19 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (4800,  '이디야커피',           '2025-08-20 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (9800,  '교보문고',           '2025-08-21 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid1, @ucid1, 0,0,0,0,0),
  (35000, '약국 강남점',         '2025-08-22 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid1, @ucid1, 0,0,0,0,0),
  (6800,  '올리브영 강남점',     '2025-08-23 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid1, @ucid1, 0,0,0,0,0),
  (7200,  '버거킹 강남역점',     '2025-08-25 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (14900, 'Netflix',             '2025-08-25 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid1, @ucid2, 0,0,0,0,0),
  (2200,  'GS25 선릉점',         '2025-08-26 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-08-27 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (8800,  '김밥천국 강남점',     '2025-08-28 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (18000, '네이버쇼핑',          '2025-08-29 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (5600,  '메가커피 역삼점',     '2025-08-30 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0);

-- ── 2025년 9월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (9200,  '김밥천국 강남점',     '2025-09-01 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (5200,  '스타벅스 테헤란로',   '2025-09-01 09:15:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-09-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (2800,  'CU 역삼역점',         '2025-09-03 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (13500, '맘스터치 선릉점',     '2025-09-04 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (42000, '쿠팡',               '2025-09-05 22:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-09-06 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (72000, '이마트 성수점',       '2025-09-07 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid1, @ucid1, 0,0,0,0,0),
  (6500,  '투썸플레이스',         '2025-09-08 14:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (55000, 'SK텔레콤',           '2025-09-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid1, @ucid1, 0,0,0,0,0),
  (14900, 'Netflix',             '2025-09-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid1, @ucid2, 0,0,0,0,0),
  (8200,  '본죽 역삼점',         '2025-09-11 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (18000, 'CGV 강남',           '2025-09-12 19:30:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-09-13 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (3200,  'GS25 선릉점',         '2025-09-14 21:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (52000, 'GS칼텍스 강남주유소', '2025-09-15 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid1, @ucid1, 0,0,0,0,0),
  (7800,  '한솥도시락 선릉점',   '2025-09-16 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (12500, '교보문고',           '2025-09-17 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid1, @ucid1, 0,0,0,0,0),
  (8900,  '올리브영 강남점',     '2025-09-18 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid1, @ucid1, 0,0,0,0,0),
  (45000, '약국 강남점',         '2025-09-19 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid1, @ucid1, 0,0,0,0,0),
  (9200,  '버거킹 강남역점',     '2025-09-20 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (4300,  '이디야커피',           '2025-09-20 15:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-09-22 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (10500, '맘스터치 선릉점',     '2025-09-24 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (5600,  '스타벅스 테헤란로',   '2025-09-25 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1800,  'GS25 선릉점',         '2025-09-26 22:30:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (7500,  '김밥천국 강남점',     '2025-09-28 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (15800, '11번가',              '2025-09-29 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (4200,  '메가커피 역삼점',     '2025-09-30 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0);

-- ── 2025년 10월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (8800,  '김밥천국 강남점',     '2025-10-01 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (4500,  '스타벅스 테헤란로',   '2025-10-01 09:10:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-10-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (15000, '맘스터치 선릉점',     '2025-10-03 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (1350,  'CU 역삼역점',         '2025-10-03 18:20:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (38000, '쿠팡',               '2025-10-05 21:30:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (7900,  '본죽 역삼점',         '2025-10-06 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (55000, 'SK텔레콤',           '2025-10-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid1, @ucid1, 0,0,0,0,0),
  (5500,  '투썸플레이스',         '2025-10-10 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (14900, 'Netflix',             '2025-10-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid1, @ucid2, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-10-11 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (65000, '이마트 성수점',       '2025-10-12 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid1, @ucid1, 0,0,0,0,0),
  (15000, 'CGV 강남',           '2025-10-13 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid1, @ucid1, 0,0,0,0,0),
  (9500,  '한솥도시락 선릉점',   '2025-10-14 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (3200,  'GS25 선릉점',         '2025-10-15 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (11000, '서브웨이 역삼점',     '2025-10-16 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (48000, 'GS칼텍스 강남주유소', '2025-10-17 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-10-18 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (4800,  '이디야커피',           '2025-10-19 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (25000, '알라딘',             '2025-10-20 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid1, @ucid1, 0,0,0,0,0),
  (35000, '약국 강남점',         '2025-10-21 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid1, @ucid1, 0,0,0,0,0),
  (6800,  '올리브영 강남점',     '2025-10-22 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid1, @ucid1, 0,0,0,0,0),
  (7200,  '버거킹 강남역점',     '2025-10-23 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (2200,  'GS25 선릉점',         '2025-10-24 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-10-25 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (22000, '네이버쇼핑',          '2025-10-26 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (5600,  '메가커피 역삼점',     '2025-10-27 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (8500,  '김밥천국 강남점',     '2025-10-28 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (12000, '다이소 강남점',       '2025-10-29 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid1, @ucid1, 0,0,0,0,0),
  (10500, '맘스터치 선릉점',     '2025-10-30 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (15800, '쿠팡',               '2025-10-30 21:00:00', 0, 'CANCELLED', @NOW, @NOW, @cat_online,@uid1, @ucid2, 0,0,0,0,0);

-- ── 2025년 11월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (9500,  '김밥천국 강남점',     '2025-11-01 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (4500,  '스타벅스 테헤란로',   '2025-11-01 09:10:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-11-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (12000, '맘스터치 선릉점',     '2025-11-03 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (2800,  'CU 역삼역점',         '2025-11-03 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (35000, '쿠팡',               '2025-11-05 22:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (7900,  '본죽 역삼점',         '2025-11-06 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-11-07 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (5500,  '투썸플레이스',         '2025-11-08 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (55000, 'SK텔레콤',           '2025-11-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid1, @ucid1, 0,0,0,0,0),
  (14900, 'Netflix',             '2025-11-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid1, @ucid2, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-11-11 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (15000, 'CGV 강남',           '2025-11-12 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid1, @ucid1, 0,0,0,0,0),
  (9800,  '교보문고',           '2025-11-13 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid1, @ucid1, 0,0,0,0,0),
  (8500,  '한솥도시락 선릉점',   '2025-11-14 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (6800,  '올리브영 강남점',     '2025-11-15 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-11-17 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (9200,  '버거킹 강남역점',     '2025-11-18 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (4300,  '이디야커피',           '2025-11-18 15:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (48000, 'GS칼텍스 강남주유소', '2025-11-19 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid1, @ucid1, 0,0,0,0,0),
  (3200,  'GS25 선릉점',         '2025-11-20 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (25000, '약국 강남점',         '2025-11-21 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid1, @ucid1, 0,0,0,0,0),
  (11000, '서브웨이 역삼점',     '2025-11-23 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (1800,  'GS25 선릉점',         '2025-11-24 22:30:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (58000, '홈플러스 성수점',     '2025-11-25 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid1, @ucid1, 0,0,0,0,0),
  (7500,  '김밥천국 강남점',     '2025-11-27 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (5600,  '스타벅스 테헤란로',   '2025-11-28 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (18500, '11번가',              '2025-11-29 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0);

-- ── 2025년 12월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (8500,  '김밥천국 강남점',     '2025-12-01 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (1350,  'CU 역삼역점',         '2025-12-01 18:20:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (4500,  '스타벅스 테헤란로',   '2025-12-03 09:10:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-03 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (12000, '맘스터치 선릉점',     '2025-12-05 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (29900, '쿠팡',               '2025-12-05 21:30:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (65000, '이마트 성수점',       '2025-12-07 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid1, @ucid1, 0,0,0,0,0),
  (7900,  '본죽 역삼점',         '2025-12-10 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (5500,  '투썸플레이스',         '2025-12-10 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (55000, 'SK텔레콤',           '2025-12-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid1, @ucid1, 0,0,0,0,0),
  (14900, 'Netflix',             '2025-12-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid1, @ucid2, 0,0,0,0,0),
  (15000, 'CGV 강남',           '2025-12-12 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid1, @ucid1, 0,0,0,0,0),
  (9800,  '교보문고',           '2025-12-15 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid1, @ucid1, 0,0,0,0,0),
  (6800,  '올리브영 강남점',     '2025-12-15 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-18 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (9500,  '한솥도시락 선릉점',   '2025-12-18 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (48000, 'GS칼텍스 강남주유소', '2025-12-20 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid1, @ucid1, 0,0,0,0,0),
  (35000, '약국 강남점',         '2025-12-22 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid1, @ucid1, 0,0,0,0,0),
  (11000, '서브웨이 역삼점',     '2025-12-25 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (4800,  '이디야커피',           '2025-12-25 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (2200,  'GS25 선릉점',         '2025-12-28 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (150000,'제주항공',             '2025-12-28 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_travel,   @uid1, @ucid1, 0,0,0,0,0),
  (7200,  '버거킹 강남역점',     '2025-12-30 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-30 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (5600,  '메가커피 역삼점',     '2025-12-31 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0);

-- ── 2026년 1월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (9500,  '김밥천국 강남점',     '2026-01-02 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (5200,  '스타벅스 테헤란로',   '2026-01-03 09:15:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (2800,  'CU 역삼역점',         '2026-01-03 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (13500, '맘스터치 선릉점',     '2026-01-05 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (42000, '쿠팡',               '2026-01-05 22:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (72000, '이마트 성수점',       '2026-01-07 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-07 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (6500,  '투썸플레이스',         '2026-01-08 14:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (8200,  '본죽 역삼점',         '2026-01-10 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (55000, 'SK텔레콤',           '2026-01-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid1, @ucid1, 0,0,0,0,0),
  (14900, 'Netflix',             '2026-01-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid1, @ucid2, 0,0,0,0,0),
  (10900, 'Spotify',             '2026-01-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid1, @ucid2, 0,0,0,0,0),
  (11500, '서브웨이 역삼점',     '2026-01-12 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (18000, 'CGV 강남',           '2026-01-12 19:30:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-14 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (3200,  'GS25 선릉점',         '2026-01-14 21:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (52000, 'GS칼텍스 강남주유소', '2026-01-15 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid1, @ucid1, 0,0,0,0,0),
  (12500, '교보문고',           '2026-01-15 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid1, @ucid1, 0,0,0,0,0),
  (8900,  '올리브영 강남점',     '2026-01-17 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid1, @ucid1, 0,0,0,0,0),
  (7800,  '한솥도시락 선릉점',   '2026-01-17 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (45000, '약국 강남점',         '2026-01-19 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid1, @ucid1, 0,0,0,0,0),
  (9200,  '버거킹 강남역점',     '2026-01-20 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (4300,  '이디야커피',           '2026-01-20 15:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (35900, '쿠팡',               '2026-01-22 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-22 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (10500, '맘스터치 선릉점',     '2026-01-24 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (5600,  '스타벅스 테헤란로',   '2026-01-24 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1800,  'GS25 선릉점',         '2026-01-26 22:30:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (7500,  '김밥천국 강남점',     '2026-01-26 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (85000, '코스트코 양재점',     '2026-01-27 14:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid1, @ucid1, 0,0,0,0,0);

-- =============================================================
-- 6. 지출 데이터 — User2 (김테스트) : 4개월 (2025-10 ~ 2026-01)
--    주력: 문화/여가 + 디지털구독 + 교통, Card2(삼성)
-- =============================================================

-- ── User2: 2025년 10월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (8500,  '김밥천국 신논현점',   '2025-10-01 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-10-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (22000, '롯데시네마 건대',     '2025-10-03 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (14900, 'Netflix',             '2025-10-05 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (14900, 'YouTube Premium',     '2025-10-05 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-10-07 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (9800,  '서브웨이 건대점',     '2025-10-08 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (5500,  '스타벅스 건대입구',   '2025-10-09 14:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid2, @ucid3, 0,0,0,0,0),
  (60000, 'KT',                 '2025-10-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-10-11 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (18000, '메가박스 코엑스',     '2025-10-12 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (28000, 'ChatGPT Plus',       '2025-10-13 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (7800,  '한솥도시락 건대점',   '2025-10-14 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-10-16 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (2500,  '세븐일레븐 건대점',   '2025-10-17 21:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (12000, '교보문고 광화문점',   '2025-10-18 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid2, @ucid3, 0,0,0,0,0),
  (15000, 'CGV 왕십리',         '2025-10-19 18:30:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-10-21 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (10500, '맘스터치 건대점',     '2025-10-22 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (35000, '쿠팡',               '2025-10-23 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid2, @ucid3, 0,0,0,0,0),
  (4300,  '이디야커피 건대점',   '2025-10-24 15:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-10-27 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (8200,  '본죽 건대점',         '2025-10-28 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (25000, '약국 건대점',         '2025-10-29 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid2, @ucid3, 0,0,0,0,0),
  (7500,  '버거킹 건대역점',     '2025-10-30 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0);

-- ── User2: 2025년 11월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (9200,  '김밥천국 신논현점',   '2025-11-01 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-11-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (14900, 'Netflix',             '2025-11-05 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (14900, 'YouTube Premium',     '2025-11-05 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (10900, 'Apple Music',         '2025-11-05 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (20000, '롯데시네마 건대',     '2025-11-06 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (5200,  '스타벅스 건대입구',   '2025-11-07 09:15:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-11-08 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (60000, 'KT',                 '2025-11-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid2, @ucid3, 0,0,0,0,0),
  (12000, '맘스터치 건대점',     '2025-11-11 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-11-12 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (15000, 'CGV 왕십리',         '2025-11-13 18:30:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (8500,  '본죽 건대점',         '2025-11-15 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-11-17 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (3800,  '세븐일레븐 건대점',   '2025-11-18 21:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (45000, '쿠팡',               '2025-11-19 22:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid2, @ucid3, 0,0,0,0,0),
  (22000, '메가박스 코엑스',     '2025-11-20 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-11-22 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (7200,  '버거킹 건대역점',     '2025-11-23 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (48000, 'SK에너지 건대주유소', '2025-11-24 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid2, @ucid3, 0,0,0,0,0),
  (18000, '알라딘 온라인',       '2025-11-25 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid2, @ucid3, 0,0,0,0,0),
  (4800,  '이디야커피 건대점',   '2025-11-27 15:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid2, @ucid3, 0,0,0,0,0),
  (9500,  '한솥도시락 건대점',   '2025-11-28 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-11-29 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0);

-- ── User2: 2025년 12월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (8800,  '김밥천국 신논현점',   '2025-12-01 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-12-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (14900, 'Netflix',             '2025-12-05 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (14900, 'YouTube Premium',     '2025-12-05 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (10900, 'Apple Music',         '2025-12-05 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (7900,  '왓챠',               '2025-12-05 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (25000, '롯데시네마 건대',     '2025-12-06 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-12-08 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (60000, 'KT',                 '2025-12-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid2, @ucid3, 0,0,0,0,0),
  (13500, '맘스터치 건대점',     '2025-12-11 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (5500,  '스타벅스 건대입구',   '2025-12-12 09:15:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-12-13 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (18000, 'CGV 왕십리',         '2025-12-14 18:30:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (9200,  '서브웨이 건대점',     '2025-12-16 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-12-17 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (55000, 'GS칼텍스 건대주유소', '2025-12-18 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid2, @ucid3, 0,0,0,0,0),
  (180000,'야놀자',              '2025-12-19 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_travel,   @uid2, @ucid3, 0,0,0,0,0),
  (2800,  '세븐일레븐 건대점',   '2025-12-20 21:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (22000, '메가박스 코엑스',     '2025-12-21 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-12-23 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (42000, '쿠팡',               '2025-12-24 22:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid2, @ucid3, 0,0,0,0,0),
  (8200,  '본죽 건대점',         '2025-12-26 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (15000, '교보문고 광화문점',   '2025-12-27 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid2, @ucid3, 0,0,0,0,0),
  (7200,  '버거킹 건대역점',     '2025-12-28 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (35000, '약국 건대점',         '2025-12-29 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2025-12-30 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (12000, '다이소 건대점',       '2025-12-30 15:00:00', 0, 'CANCELLED', @NOW, @NOW, @cat_beauty,@uid2, @ucid3, 0,0,0,0,0);

-- ── User2: 2026년 1월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (9500,  '김밥천국 신논현점',   '2026-01-02 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2026-01-03 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (14900, 'Netflix',             '2026-01-05 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (14900, 'YouTube Premium',     '2026-01-05 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (10900, 'Apple Music',         '2026-01-05 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (7900,  '왓챠',               '2026-01-05 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (5200,  '스타벅스 건대입구',   '2026-01-06 09:15:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid2, @ucid3, 0,0,0,0,0),
  (22000, '롯데시네마 건대',     '2026-01-07 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2026-01-08 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (60000, 'KT',                 '2026-01-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid2, @ucid3, 0,0,0,0,0),
  (12000, '맘스터치 건대점',     '2026-01-11 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2026-01-12 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (18000, 'CGV 왕십리',         '2026-01-13 18:30:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (8200,  '본죽 건대점',         '2026-01-14 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (3500,  '세븐일레븐 건대점',   '2026-01-15 21:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (52000, 'SK에너지 건대주유소', '2026-01-16 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2026-01-17 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (15000, '메가박스 코엑스',     '2026-01-18 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (38000, '쿠팡',               '2026-01-19 22:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid2, @ucid3, 0,0,0,0,0),
  (9500,  '한솥도시락 건대점',   '2026-01-20 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (4300,  '이디야커피 건대점',   '2026-01-21 15:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2026-01-23 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (7200,  '버거킹 건대역점',     '2026-01-24 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (25000, '교보문고 광화문점',   '2026-01-25 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid2, @ucid3, 0,0,0,0,0),
  (8500,  '올리브영 건대점',     '2026-01-26 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid2, @ucid3, 0,0,0,0,0),
  (1350,  '서울교통공사',         '2026-01-27 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0);

-- =============================================================
-- 7. 지출 데이터 — User3 (박샘플) : 3개월 (2025-11 ~ 2026-01)
--    주력: 뷰티/잡화 + 대형마트 + 카페, Card3(현대)
-- =============================================================

-- ── User3: 2025년 11월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (7500,  '김밥천국 홍대점',     '2025-11-01 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid3, @ucid4, 0,0,0,0,0),
  (6500,  '스타벅스 홍대입구',   '2025-11-02 09:10:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-11-03 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid3, @ucid4, 0,0,0,0,0),
  (25000, '올리브영 홍대점',     '2025-11-04 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid3, @ucid4, 0,0,0,0,0),
  (85000, '코스트코 상암점',     '2025-11-05 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (5800,  '투썸플레이스 홍대점', '2025-11-07 14:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (2500,  'CU 홍대점',           '2025-11-08 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid3, @ucid4, 0,0,0,0,0),
  (50000, 'SK텔레콤',           '2025-11-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid3, @ucid4, 0,0,0,0,0),
  (18000, '다이소 홍대점',       '2025-11-11 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid3, @ucid4, 0,0,0,0,0),
  (9800,  '맘스터치 홍대점',     '2025-11-12 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid3, @ucid4, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-11-13 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid3, @ucid4, 0,0,0,0,0),
  (12000, 'CGV 홍대',           '2025-11-14 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid3, @ucid4, 0,0,0,0,0),
  (4500,  '이디야커피 홍대점',   '2025-11-16 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (30000, '올리브영 홍대점',     '2025-11-17 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid3, @ucid4, 0,0,0,0,0),
  (65000, '이마트 마포점',       '2025-11-19 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (8200,  '본죽 홍대점',         '2025-11-20 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid3, @ucid4, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-11-22 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid3, @ucid4, 0,0,0,0,0),
  (15000, '교보문고 합정점',     '2025-11-23 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid3, @ucid4, 0,0,0,0,0),
  (5600,  '메가커피 홍대점',     '2025-11-25 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (3200,  'GS25 홍대점',         '2025-11-26 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid3, @ucid4, 0,0,0,0,0),
  (7200,  '버거킹 홍대역점',     '2025-11-28 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid3, @ucid4, 0,0,0,0,0),
  (10900, 'Spotify',             '2025-11-28 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid3, @ucid4, 0,0,0,0,0),
  (22000, '쿠팡',               '2025-11-29 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid3, @ucid4, 0,0,0,0,0);

-- ── User3: 2025년 12월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (8800,  '김밥천국 홍대점',     '2025-12-01 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid3, @ucid4, 0,0,0,0,0),
  (6500,  '스타벅스 홍대입구',   '2025-12-02 09:10:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-03 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid3, @ucid4, 0,0,0,0,0),
  (28000, '올리브영 홍대점',     '2025-12-04 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid3, @ucid4, 0,0,0,0,0),
  (95000, '코스트코 상암점',     '2025-12-06 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (5800,  '투썸플레이스 홍대점', '2025-12-07 14:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (50000, 'SK텔레콤',           '2025-12-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid3, @ucid4, 0,0,0,0,0),
  (10900, 'Spotify',             '2025-12-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid3, @ucid4, 0,0,0,0,0),
  (15000, '다이소 홍대점',       '2025-12-11 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid3, @ucid4, 0,0,0,0,0),
  (11000, '서브웨이 홍대점',     '2025-12-12 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid3, @ucid4, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-13 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid3, @ucid4, 0,0,0,0,0),
  (15000, 'CGV 홍대',           '2025-12-14 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid3, @ucid4, 0,0,0,0,0),
  (4500,  '이디야커피 홍대점',   '2025-12-15 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (72000, '이마트 마포점',       '2025-12-17 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (22000, '올리브영 홍대점',     '2025-12-18 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid3, @ucid4, 0,0,0,0,0),
  (9800,  '맘스터치 홍대점',     '2025-12-19 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid3, @ucid4, 0,0,0,0,0),
  (3800,  'CU 홍대점',           '2025-12-20 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid3, @ucid4, 0,0,0,0,0),
  (48000, 'GS칼텍스 마포주유소', '2025-12-21 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid3, @ucid4, 0,0,0,0,0),
  (200000,'제주항공',             '2025-12-22 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_travel,   @uid3, @ucid4, 0,0,0,0,0),
  (35000, '약국 홍대점',         '2025-12-23 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid3, @ucid4, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-24 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid3, @ucid4, 0,0,0,0,0),
  (5600,  '메가커피 홍대점',     '2025-12-25 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (18000, '네이버쇼핑',          '2025-12-26 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid3, @ucid4, 0,0,0,0,0),
  (12000, '알라딘',             '2025-12-27 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid3, @ucid4, 0,0,0,0,0),
  (7200,  '버거킹 홍대역점',     '2025-12-29 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid3, @ucid4, 0,0,0,0,0),
  (15000, '쿠팡',               '2025-12-30 21:00:00', 0, 'CANCELLED', @NOW, @NOW, @cat_online,@uid3, @ucid4, 0,0,0,0,0);

-- ── User3: 2026년 1월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (9200,  '김밥천국 홍대점',     '2026-01-02 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid3, @ucid4, 0,0,0,0,0),
  (6500,  '스타벅스 홍대입구',   '2026-01-03 09:10:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-03 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid3, @ucid4, 0,0,0,0,0),
  (32000, '올리브영 홍대점',     '2026-01-04 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid3, @ucid4, 0,0,0,0,0),
  (110000,'홈플러스 합정점',     '2026-01-05 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (5800,  '투썸플레이스 홍대점', '2026-01-07 14:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (3200,  'CU 홍대점',           '2026-01-08 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid3, @ucid4, 0,0,0,0,0),
  (50000, 'SK텔레콤',           '2026-01-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid3, @ucid4, 0,0,0,0,0),
  (10900, 'Spotify',             '2026-01-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid3, @ucid4, 0,0,0,0,0),
  (20000, '다이소 홍대점',       '2026-01-11 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid3, @ucid4, 0,0,0,0,0),
  (11000, '서브웨이 홍대점',     '2026-01-12 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid3, @ucid4, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-13 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid3, @ucid4, 0,0,0,0,0),
  (18000, 'CGV 홍대',           '2026-01-14 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid3, @ucid4, 0,0,0,0,0),
  (4500,  '이디야커피 홍대점',   '2026-01-15 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (25000, '올리브영 홍대점',     '2026-01-16 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid3, @ucid4, 0,0,0,0,0),
  (75000, '이마트 마포점',       '2026-01-18 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (8200,  '본죽 홍대점',         '2026-01-19 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid3, @ucid4, 0,0,0,0,0),
  (42000, '쿠팡',               '2026-01-20 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid3, @ucid4, 0,0,0,0,0),
  (45000, 'GS칼텍스 마포주유소', '2026-01-21 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid3, @ucid4, 0,0,0,0,0),
  (15000, '교보문고 합정점',     '2026-01-22 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid3, @ucid4, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-23 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid3, @ucid4, 0,0,0,0,0),
  (7200,  '버거킹 홍대역점',     '2026-01-24 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid3, @ucid4, 0,0,0,0,0),
  (5600,  '메가커피 홍대점',     '2026-01-25 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (28000, '약국 홍대점',         '2026-01-26 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid3, @ucid4, 0,0,0,0,0),
  (2500,  'GS25 홍대점',         '2026-01-27 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid3, @ucid4, 0,0,0,0,0);

-- =============================================================
-- 8. 구독 데이터
-- =============================================================

-- User1 구독
INSERT INTO subscriptions
  (service_name, monthly_fee, next_billing, status, created_at, updated_at, category_id, user_card_id, user_id)
VALUES
  ('Netflix',         14900, '2026-02-10', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid2, @uid1),
  ('Spotify',         10900, '2026-02-15', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid2, @uid1),
  ('YouTube Premium', 14900, '2026-02-05', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid2, @uid1),
  ('ChatGPT Plus',    28000, '2026-02-18', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid2, @uid1),
  ('Claude Pro',      28000, '2026-02-20', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid2, @uid1),
  ('쿠팡 로켓와우',   4990,  '2026-02-01', 'ACTIVE',   @NOW, @NOW, @cat_online,  @ucid2, @uid1),
  ('네이버 플러스',    4900,  '2026-02-12', 'ACTIVE',   @NOW, @NOW, @cat_online,  @ucid2, @uid1),
  ('밀리의서재',       9900,  '2026-02-08', 'CANCELED', @NOW, @NOW, @cat_edu,     @ucid2, @uid1);

-- User2 구독
INSERT INTO subscriptions
  (service_name, monthly_fee, next_billing, status, created_at, updated_at, category_id, user_card_id, user_id)
VALUES
  ('Netflix',         14900, '2026-02-10', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid3, @uid2),
  ('YouTube Premium', 14900, '2026-02-05', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid3, @uid2),
  ('Apple Music',     10900, '2026-02-15', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid3, @uid2),
  ('왓챠',            7900,  '2026-02-08', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid3, @uid2);

-- User3 구독
INSERT INTO subscriptions
  (service_name, monthly_fee, next_billing, status, created_at, updated_at, category_id, user_card_id, user_id)
VALUES
  ('Spotify',         10900, '2026-02-15', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid4, @uid3),
  ('쿠팡 로켓와우',   4990,  '2026-02-01', 'ACTIVE',   @NOW, @NOW, @cat_online,  @ucid4, @uid3),
  ('네이버 플러스',    4900,  '2026-02-12', 'ACTIVE',   @NOW, @NOW, @cat_online,  @ucid4, @uid3);

-- =============================================================
-- 9. 월별 통계 데이터 (지출 데이터가 있는 월만, 정합성 보장)
-- =============================================================

-- User1 (한정수)
INSERT INTO monthly_stats
  (target_month, total_spent, total_benefit, avg_group_spent, user_id, created_at, updated_at)
VALUES
  ('2025-08', 324550,  12982, 380000, @uid1, @NOW, @NOW),
  ('2025-09', 440600,  17624, 395000, @uid1, @NOW, @NOW),
  ('2025-10', 447250,  17890, 410000, @uid1, @NOW, @NOW),
  ('2025-11', 384300,  15372, 400000, @uid1, @NOW, @NOW),
  ('2025-12', 513200,  20528, 450000, @uid1, @NOW, @NOW),
  ('2026-01', 564200,  22568, 460000, @uid1, @NOW, @NOW);

-- User2 (김테스트) — 지출 데이터: 2025-10 ~ 2026-01
INSERT INTO monthly_stats
  (target_month, total_spent, total_benefit, avg_group_spent, user_id, created_at, updated_at)
VALUES
  ('2025-10', 317500,  12700, 410000, @uid2, @NOW, @NOW),
  ('2025-11', 337000,  13480, 400000, @uid2, @NOW, @NOW),
  ('2025-12', 563900,  22556, 450000, @uid2, @NOW, @NOW),
  ('2026-01', 354600,  14184, 460000, @uid2, @NOW, @NOW);

-- User3 (박샘플) — 지출 데이터: 2025-11 ~ 2026-01
INSERT INTO monthly_stats
  (target_month, total_spent, total_benefit, avg_group_spent, user_id, created_at, updated_at)
VALUES
  ('2025-11', 397450,  15898, 400000, @uid3, @NOW, @NOW),
  ('2025-12', 687650,  27506, 450000, @uid3, @NOW, @NOW),
  ('2026-01', 538350,  21534, 460000, @uid3, @NOW, @NOW);

-- =============================================================
-- 완료 확인
-- =============================================================
SELECT '=== Seed 완료 ===' AS result;

SELECT '--- User별 거래 건수 ---' AS info;
SELECT u.name, COUNT(*) AS total_expenses
FROM expenses e JOIN users u ON e.user_id = u.user_id
WHERE u.email IN ('mockuser@test.com', 'testuser2@test.com', 'testuser3@test.com')
GROUP BY u.name;

SELECT '--- User1 월별 거래 건수 ---' AS info;
SELECT DATE_FORMAT(spent_at, '%Y-%m') AS month, COUNT(*) AS cnt, SUM(amount) AS total
FROM expenses WHERE user_id = @uid1
GROUP BY DATE_FORMAT(spent_at, '%Y-%m')
ORDER BY month;

SELECT '--- 구독 현황 ---' AS info;
SELECT u.name, COUNT(*) AS subs_count
FROM subscriptions s JOIN users u ON s.user_id = u.user_id
GROUP BY u.name;

SELECT '--- 카드 혜택 ---' AS info;
SELECT c.card_name, COUNT(*) AS benefit_count
FROM card_benefits cb JOIN cards c ON cb.card_id = c.card_id
GROUP BY c.card_name;

SELECT '--- 카테고리별 전체 거래 ---' AS info;
SELECT cat.category_name, COUNT(*) AS cnt
FROM expenses e JOIN category cat ON e.category_id = cat.category_id
GROUP BY cat.category_name
ORDER BY cnt DESC;
