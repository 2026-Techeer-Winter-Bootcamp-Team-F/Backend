-- =============================================================
-- Mock Data Seed Script
-- 테스트용 사용자 + 카드 + 카테고리 + 2개월치 지출 데이터 생성
-- 사용법: docker exec -i mysqldb mysql -u root -proot --default-character-set=utf8mb4 card_recommend_db < scripts/seed_mock_data.sql
-- =============================================================

SET NAMES utf8mb4;
SET @NOW = NOW();

-- -------------------------------------------------------------
-- 1. 카테고리 (14종, CATEGORY_MAPPING 기준)
--    기존 카테고리와 중복 방지: INSERT IGNORE
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
-- 2. 테스트 사용자
-- -------------------------------------------------------------
INSERT INTO users (email, password, name, age_group, gender, created_at, updated_at, is_active, phone, birth_date)
VALUES ('mockuser@test.com', 'mock1234', '목데이터', '20대', 0, @NOW, @NOW, 1, '01011112222', '19990301');

SET @uid = LAST_INSERT_ID();

-- -------------------------------------------------------------
-- 3. 카드 + 유저카드
-- -------------------------------------------------------------
INSERT INTO cards (card_name, company, annual_fee_domestic, annual_fee_overseas, created_at, updated_at)
VALUES ('테스트 신한카드', '신한카드', 0, 0, @NOW, @NOW);

SET @cid = LAST_INSERT_ID();

INSERT INTO user_cards (registered_at, created_at, updated_at, card_id, user_id, card_number)
VALUES (@NOW, @NOW, @NOW, @cid, @uid, '123456******7890');

SET @ucid = LAST_INSERT_ID();

-- -------------------------------------------------------------
-- 4. 지출 데이터 — 2025년 12월 (전월)
-- -------------------------------------------------------------
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  -- 12/1
  (8500,  '김밥천국 강남점',     '2025-12-01 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0),
  (1350,  'CU 역삼역점',         '2025-12-01 18:20:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid, @ucid, 0, 0, 0, 0, 0),
  -- 12/3
  (4500,  '스타벅스 테헤란로',   '2025-12-03 09:10:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid, @ucid, 0, 0, 0, 0, 0),
  (1250,  '서울교통공사',         '2025-12-03 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid, @ucid, 0, 0, 0, 0, 0),
  -- 12/5
  (12000, '맘스터치 선릉점',     '2025-12-05 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0),
  (29900, '쿠팡',               '2025-12-05 21:30:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid, @ucid, 0, 0, 0, 0, 0),
  -- 12/7
  (65000, '이마트 성수점',       '2025-12-07 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid, @ucid, 0, 0, 0, 0, 0),
  -- 12/10
  (7900,  '본죽 역삼점',         '2025-12-10 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0),
  (5500,  '투썸플레이스',         '2025-12-10 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid, @ucid, 0, 0, 0, 0, 0),
  (55000, 'SK텔레콤',           '2025-12-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid, @ucid, 0, 0, 0, 0, 0),
  -- 12/12
  (15000, 'CGV 강남',           '2025-12-12 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid, @ucid, 0, 0, 0, 0, 0),
  -- 12/15
  (9800,  '교보문고',           '2025-12-15 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid, @ucid, 0, 0, 0, 0, 0),
  (6800,  '올리브영 강남점',     '2025-12-15 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid, @ucid, 0, 0, 0, 0, 0),
  -- 12/18
  (1250,  '서울교통공사',         '2025-12-18 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid, @ucid, 0, 0, 0, 0, 0),
  (9500,  '한솥도시락 선릉점',   '2025-12-18 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0),
  -- 12/20
  (14900, 'Netflix',             '2025-12-20 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid, @ucid, 0, 0, 0, 0, 0),
  (48000, 'GS칼텍스 강남주유소', '2025-12-20 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid, @ucid, 0, 0, 0, 0, 0),
  -- 12/22
  (35000, '약국 강남점',         '2025-12-22 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid, @ucid, 0, 0, 0, 0, 0),
  -- 12/25
  (11000, '서브웨이 역삼점',     '2025-12-25 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0),
  (4800,  '이디야커피',           '2025-12-25 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid, @ucid, 0, 0, 0, 0, 0),
  -- 12/28
  (2200,  'GS25 선릉점',         '2025-12-28 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid, @ucid, 0, 0, 0, 0, 0),
  (150000,'제주항공',             '2025-12-28 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_travel,   @uid, @ucid, 0, 0, 0, 0, 0),
  -- 12/30
  (7200,  '버거킹 강남역점',     '2025-12-30 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0);

-- -------------------------------------------------------------
-- 5. 지출 데이터 — 2026년 1월 (이번 달)
-- -------------------------------------------------------------
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  -- 1/2
  (9500,  '김밥천국 강남점',     '2026-01-02 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0),
  (1250,  '서울교통공사',         '2026-01-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/3
  (5200,  '스타벅스 테헤란로',   '2026-01-03 09:15:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid, @ucid, 0, 0, 0, 0, 0),
  (2800,  'CU 역삼역점',         '2026-01-03 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/5
  (13500, '맘스터치 선릉점',     '2026-01-05 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0),
  (42000, '쿠팡',               '2026-01-05 22:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/7
  (72000, '이마트 성수점',       '2026-01-07 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid, @ucid, 0, 0, 0, 0, 0),
  (1250,  '서울교통공사',         '2026-01-07 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/8
  (6500,  '투썸플레이스',         '2026-01-08 14:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/10
  (8200,  '본죽 역삼점',         '2026-01-10 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0),
  (55000, 'SK텔레콤',           '2026-01-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid, @ucid, 0, 0, 0, 0, 0),
  (14900, 'Netflix',             '2026-01-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/12
  (11500, '서브웨이 역삼점',     '2026-01-12 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0),
  (18000, 'CGV 강남',           '2026-01-12 19:30:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/14
  (1250,  '서울교통공사',         '2026-01-14 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid, @ucid, 0, 0, 0, 0, 0),
  (3200,  'GS25 선릉점',         '2026-01-14 21:00:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/15
  (52000, 'GS칼텍스 강남주유소', '2026-01-15 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid, @ucid, 0, 0, 0, 0, 0),
  (12500, '교보문고',           '2026-01-15 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/17
  (8900,  '올리브영 강남점',     '2026-01-17 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid, @ucid, 0, 0, 0, 0, 0),
  (7800,  '한솥도시락 선릉점',   '2026-01-17 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/19
  (45000, '약국 강남점',         '2026-01-19 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/20
  (9200,  '버거킹 강남역점',     '2026-01-20 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0),
  (4300,  '이디야커피',           '2026-01-20 15:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/22
  (35900, '쿠팡',               '2026-01-22 20:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid, @ucid, 0, 0, 0, 0, 0),
  (1250,  '서울교통공사',         '2026-01-22 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/24
  (10500, '맘스터치 선릉점',     '2026-01-24 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0),
  (5600,  '스타벅스 테헤란로',   '2026-01-24 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid, @ucid, 0, 0, 0, 0, 0),
  -- 1/26
  (1800,  'GS25 선릉점',         '2026-01-26 22:30:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid, @ucid, 0, 0, 0, 0, 0),
  (7500,  '김밥천국 강남점',     '2026-01-26 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid, @ucid, 0, 0, 0, 0, 0);

-- -------------------------------------------------------------
-- 6. 구독 데이터
-- -------------------------------------------------------------
INSERT INTO subscriptions
  (service_name, monthly_fee, next_billing, status, created_at, updated_at, category_id, user_card_id, user_id)
VALUES
  ('Netflix',        14900, '2026-02-10', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid, @uid),
  ('Spotify',        10900, '2026-02-15', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid, @uid),
  ('YouTube Premium', 14900, '2026-02-05', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid, @uid),
  ('ChatGPT Plus',   28000, '2026-02-18', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid, @uid),
  ('Claude Pro',     28000, '2026-02-20', 'ACTIVE',   @NOW, @NOW, @cat_digital, @ucid, @uid),
  ('쿠팡 로켓와우',  4990,  '2026-02-01', 'ACTIVE',   @NOW, @NOW, @cat_online,  @ucid, @uid),
  ('네이버 플러스',   4900,  '2026-02-12', 'ACTIVE',   @NOW, @NOW, @cat_online,  @ucid, @uid),
  ('밀리의서재',      9900,  '2026-02-08', 'CANCELED', @NOW, @NOW, @cat_edu,     @ucid, @uid);

-- -------------------------------------------------------------
-- 7. 월별 통계 데이터 (최근 6개월)
-- -------------------------------------------------------------
INSERT INTO monthly_stats
  (target_month, total_spent, total_benefit, avg_group_spent, user_id, created_at, updated_at)
VALUES
  ('2025-08', 320000,  12800, 410000, @uid, @NOW, @NOW),
  ('2025-09', 385000,  15400, 420000, @uid, @NOW, @NOW),
  ('2025-10', 410000,  16400, 405000, @uid, @NOW, @NOW),
  ('2025-11', 370000,  14800, 415000, @uid, @NOW, @NOW),
  ('2025-12', 496950,  19878, 430000, @uid, @NOW, @NOW),
  ('2026-01', 468300,  18732, 425000, @uid, @NOW, @NOW);

-- -------------------------------------------------------------
-- 완료 확인
-- -------------------------------------------------------------
SELECT '=== Seed 완료 ===' AS result;
SELECT COUNT(*) AS total_mock_expenses FROM expenses WHERE user_id = @uid;
SELECT COUNT(*) AS total_mock_subscriptions FROM subscriptions WHERE user_id = @uid;
SELECT COUNT(*) AS total_mock_monthly_stats FROM monthly_stats WHERE user_id = @uid;
SELECT category_name, COUNT(*) AS cnt
FROM expenses e JOIN category c ON e.category_id = c.category_id
WHERE e.user_id = @uid
GROUP BY category_name
ORDER BY cnt DESC;
