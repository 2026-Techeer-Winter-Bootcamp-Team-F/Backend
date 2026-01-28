-- =============================================================
-- Mock Data Seed Script (확장판 + 실제 카드 데이터)
-- 테스트용 사용자 3명 + 실제 카드 50종 + 카테고리 + 6개월치 지출 데이터
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
-- 3. 실제 카드 데이터 (50종) - Card Gorilla CSV
-- -------------------------------------------------------------

-- Card 1: 삼성 iD SELECT ALL 카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('삼성 iD SELECT ALL 카드', '삼성카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2885/card_img/44212/2885card_1.png', 20000, 20000, '전월실적 40 만원 이상', '최대 87.2만원 혜택', @NOW, @NOW);
SET @card1 = LAST_INSERT_ID();

-- Card 2: 신한카드 Mr.Life
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('신한카드 Mr.Life', '신한카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/13/card_img/28201/13card.png', 0, 15000, '전월실적 30 만원 이상', '최대 29만원 캐시백', @NOW, @NOW);
SET @card2 = LAST_INSERT_ID();

-- Card 3: 삼성카드 & MILEAGE PLATINUM (스카이패스)
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('삼성카드 & MILEAGE PLATINUM (스카이패스)', '삼성카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/49/card_img/42288/49card.png', 47000, 49000, '전월실적 없음', '최대 75만원 혜택', @NOW, @NOW);
SET @card3 = LAST_INSERT_ID();

-- Card 4: 카드의정석 SHOPPING+
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('카드의정석 SHOPPING+', '우리카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2687/card_img/33239/2687card.png', 10000, 12000, '전월실적 30 만원 이상', '최대 57.5만원 혜택', @NOW, @NOW);
SET @card4 = LAST_INSERT_ID();

-- Card 5: THE 1 (스카이패스)
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('THE 1 (스카이패스)', '삼성카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/1909/card_img/28087/1909card.png', 245000, 250000, '전월실적 30 만원 이상', '기존회원 최대 22.2만원 혜택', @NOW, @NOW);
SET @card5 = LAST_INSERT_ID();

-- Card 6: KB국민 My WE:SH 카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('KB국민 My WE:SH 카드', 'KB국민카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2441/card_img/37123/2441card_3.png', 15000, 15000, '전월실적 40 만원 이상', '최대 21만원 캐시백', @NOW, @NOW);
SET @card6 = LAST_INSERT_ID();

-- Card 7: 삼성카드 taptap O
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('삼성카드 taptap O', '삼성카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/51/card_img/37691/51card.png', 10000, 10000, '전월실적 30 만원 이상', '최대 84.2만원 혜택', @NOW, @NOW);
SET @card7 = LAST_INSERT_ID();

-- Card 8: LOCA 365 카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('LOCA 365 카드', '롯데카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2330/card_img/24131/2330card.png', 20000, 20000, '전월실적 50 만원 이상', '최대 44만원 혜택', @NOW, @NOW);
SET @card8 = LAST_INSERT_ID();

-- Card 9: ONE 체크카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('ONE 체크카드', '케이뱅크', 'https://d1c5n4ri2guedi.cloudfront.net/card/2749/card_img/44896/2749card_1.png', 0, 0, '전월실적 없음', '', @NOW, @NOW);
SET @card9 = LAST_INSERT_ID();

-- Card 10: KB Youth Club 체크카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('KB Youth Club 체크카드', 'KB국민카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2929/card_img/45849/2929card_1.png', 0, 0, '전월실적 15 만원 이상', '최대 3만원 캐시백', @NOW, @NOW);
SET @card10 = LAST_INSERT_ID();

-- Card 11: 현대카드 M
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('현대카드 M', '현대카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2669/card_img/43704/2669card_5.png', 30000, 30000, '전월실적 50 만원 이상', '최대 31.5만원 캐시백', @NOW, @NOW);
SET @card11 = LAST_INSERT_ID();

-- Card 12: American Express® Gold Card Edition2
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('American Express® Gold Card Edition2', '현대카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2663/card_img/32407/2663card.png', 0, 300000, '전월실적 50 만원 이상', '최대 40만원 캐시백', @NOW, @NOW);
SET @card12 = LAST_INSERT_ID();

-- Card 13: 굿데이카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('굿데이카드', 'KB국민카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/106/card_img/20264/106card.png', 5000, 10000, '전월실적 30 만원 이상', '최대 21만원 캐시백', @NOW, @NOW);
SET @card13 = LAST_INSERT_ID();

-- Card 14: taptap DIGITAL
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('taptap DIGITAL', '삼성카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/657/card_img/27715/657card.png', 10000, 10000, '전월실적 30 만원 이상', '최대 84.2만원 혜택', @NOW, @NOW);
SET @card14 = LAST_INSERT_ID();

-- Card 15: 삼성 iD SELECT ON 카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('삼성 iD SELECT ON 카드', '삼성카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2886/card_img/44215/2886card_1.png', 20000, 20000, '전월실적 30 만원 이상', '최대 87.2만원 혜택', @NOW, @NOW);
SET @card15 = LAST_INSERT_ID();

-- Card 16: 카드의정석 EVERY DISCOUNT
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('카드의정석 EVERY DISCOUNT', '우리카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2719/card_img/46400/2719card.png', 12000, 12000, '전월실적 없음', '최대 45.5만원 혜택', @NOW, @NOW);
SET @card16 = LAST_INSERT_ID();

-- Card 17: 노리2 체크카드(KB Pay)
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('노리2 체크카드(KB Pay)', 'KB국민카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2422/card_img/27141/2422card.png', 0, 0, '전월실적 20 만원 이상', '최대 3만원 캐시백', @NOW, @NOW);
SET @card17 = LAST_INSERT_ID();

-- Card 18: 신한카드 SOL트래블 체크
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('신한카드 SOL트래블 체크', '신한카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2667/card_img/32473/2660card.png', 0, 0, '전월실적 없음', '', @NOW, @NOW);
SET @card18 = LAST_INSERT_ID();

-- Card 19: 신한카드 처음(ANNIVERSE)
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('신한카드 처음(ANNIVERSE)', '신한카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2759/card_img/37240/2759card.png', 15000, 18000, '전월실적 30 만원 이상', '최대 29만원 캐시백', @NOW, @NOW);
SET @card19 = LAST_INSERT_ID();

-- Card 20: 가온올림카드(실속형)
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('가온올림카드(실속형)', 'KB국민카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/769/card_img/22243/769card.png', 15000, 15000, '전월실적 없음', '최대 21만원 캐시백', @NOW, @NOW);
SET @card20 = LAST_INSERT_ID();

-- Card 21: 신한카드 Deep Oil
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('신한카드 Deep Oil', '신한카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/39/card_img/31864/39card.png', 0, 10000, '전월실적 30 만원 이상', '최대 29만원 캐시백', @NOW, @NOW);
SET @card21 = LAST_INSERT_ID();

-- Card 22: 쿠팡 와우카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('쿠팡 와우카드', 'KB국민카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2609/card_img/31241/2609card.png', 20000, 20000, '전월실적 없음', '최대 11.7만원 혜택', @NOW, @NOW);
SET @card22 = LAST_INSERT_ID();

-- Card 23: 카드의정석2
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('카드의정석2', '우리카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2848/card_img/45022/2848card_1.png', 22000, 22000, '전월실적 50 만원 이상', '최대 57.5만원 혜택', @NOW, @NOW);
SET @card23 = LAST_INSERT_ID();

-- Card 24: LOCA LIKIT 1.2
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('LOCA LIKIT 1.2', '롯데카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2261/card_img/21011/2261card.png', 10000, 10000, '전월실적 없음', '최대 31만원 혜택', @NOW, @NOW);
SET @card24 = LAST_INSERT_ID();

-- Card 25: 삼성 iD SIMPLE 카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('삼성 iD SIMPLE 카드', '삼성카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2376/card_img/27725/2376card.png', 7000, 7000, '전월실적 없음', '최대 84.2만원 혜택', @NOW, @NOW);
SET @card25 = LAST_INSERT_ID();

-- Card 26: 메리어트 본보이™ 더 베스트 신한카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('메리어트 본보이™ 더 베스트 신한카드', '신한카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/716/card_img/22190/716card.png', 264000, 267000, '전월실적 없음', '최대 34만원 캐시백', @NOW, @NOW);
SET @card26 = LAST_INSERT_ID();

-- Card 27: BC 바로 On&Off 카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('BC 바로 On&Off 카드', 'BC 바로카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2591/card_img/30912/2591card.png', 5000, 5000, '전월실적 30 만원 이상', '최대 25만원 혜택', @NOW, @NOW);
SET @card27 = LAST_INSERT_ID();

-- Card 28: 신한카드 Discount Plan+
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('신한카드 Discount Plan+', '신한카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2835/card_img/41600/2835card.png', 50000, 50000, '전월실적 40 만원 이상', '최대 55만원 캐시백', @NOW, @NOW);
SET @card28 = LAST_INSERT_ID();

-- Card 29: 삼성 iD GLOBAL 카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('삼성 iD GLOBAL 카드', '삼성카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2676/card_img/32887/2676card_2.png', 20000, 20000, '전월실적 50 만원 이상', '최대 84.2만원 혜택', @NOW, @NOW);
SET @card29 = LAST_INSERT_ID();

-- Card 30: 모빌리언스카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('모빌리언스카드', 'KG모빌리언스', 'https://d1c5n4ri2guedi.cloudfront.net/card/2321/card_img/23849/2321card.png', 0, 0, '전월실적 없음', '', @NOW, @NOW);
SET @card30 = LAST_INSERT_ID();

-- Card 31: WE:SH Travel
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('WE:SH Travel', 'KB국민카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2685/card_img/37137/2685ard_2.png', 25000, 25000, '전월실적 30 만원 이상', '최대 21만원 캐시백', @NOW, @NOW);
SET @card31 = LAST_INSERT_ID();

-- Card 32: 디지로카 London
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('디지로카 London', '롯데카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2632/card_img/41192/2632card.png', 20000, 20000, '전월실적 없음', '최대 44만원 혜택', @NOW, @NOW);
SET @card32 = LAST_INSERT_ID();

-- Card 33: 올바른 FLEX 카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('올바른 FLEX 카드', 'NH농협카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/666/card_img/21431/666card.png', 10000, 12000, '전월실적 30 만원 이상', '최대 12만원 캐시백', @NOW, @NOW);
SET @card33 = LAST_INSERT_ID();

-- Card 34: 굿데이올림카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('굿데이올림카드', 'KB국민카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/115/card_img/20273/115card.png', 15000, 20000, '전월실적 30 만원 이상', '최대 21만원 캐시백', @NOW, @NOW);
SET @card34 = LAST_INSERT_ID();

-- Card 35: 카드의정석 EVERY MILE SKYPASS
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('카드의정석 EVERY MILE SKYPASS', '우리카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2553/card_img/44235/2553card.png', 39000, 39000, '전월실적 없음', '3.9만원 캐시백', @NOW, @NOW);
SET @card35 = LAST_INSERT_ID();

-- Card 36: 우리카드 MILE&POINT
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('우리카드 MILE&POINT', '우리카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2898/card_img/44541/2898card.png', 75000, 75000, '전월실적 50 만원 이상', '최대 57.5만원 혜택', @NOW, @NOW);
SET @card36 = LAST_INSERT_ID();

-- Card 37: THE iD. 1st
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('THE iD. 1st', '삼성카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2915/card_img/45262/2915card_1.png', 150000, 150000, '전월실적 50 만원 이상', '기존회원 최대 12.2만원 혜택', @NOW, @NOW);
SET @card37 = LAST_INSERT_ID();

-- Card 38: 신한카드 The CLASSIC-S
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('신한카드 The CLASSIC-S', '신한카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/945/card_img/21598/945card.png', 97000, 100000, '전월실적 없음', '최대 34만원 캐시백', @NOW, @NOW);
SET @card38 = LAST_INSERT_ID();

-- Card 39: 우리카드 7CORE
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('우리카드 7CORE', '우리카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2851/card_img/43400/2851.png', 0, 50000, '전월실적 50 만원 이상', '최대 57.5만원 혜택', @NOW, @NOW);
SET @card39 = LAST_INSERT_ID();

-- Card 40: 현대카드 ZERO Up
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('현대카드 ZERO Up', '현대카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2844/card_img/43699/2844card.png', 30000, 30000, '전월실적 없음', '3만원 캐시백', @NOW, @NOW);
SET @card40 = LAST_INSERT_ID();

-- Card 41: 신한카드 Air One
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('신한카드 Air One', '신한카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/466/card_img/37854/466card.png', 0, 49000, '전월실적 50 만원 이상', '최대 55만원 캐시백', @NOW, @NOW);
SET @card41 = LAST_INSERT_ID();

-- Card 42: 디지로카 Las Vegas
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('디지로카 Las Vegas', '롯데카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2707/card_img/34645/2707card.png', 20000, 20000, '전월실적 없음', '최대 44만원 혜택', @NOW, @NOW);
SET @card42 = LAST_INSERT_ID();

-- Card 43: 네이버페이 머니카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('네이버페이 머니카드', '네이버페이', 'https://d1c5n4ri2guedi.cloudfront.net/card/2626/card_img/31677/2625card_1.png', 0, 0, '전월실적 없음', '', @NOW, @NOW);
SET @card43 = LAST_INSERT_ID();

-- Card 44: JADE Classic
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('JADE Classic', '하나카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2657/card_img/32434/2657card.png', 115000, 120000, '전월실적 50 만원 이상', '', @NOW, @NOW);
SET @card44 = LAST_INSERT_ID();

-- Card 45: 현대카드ZERO Edition3(할인형)
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('현대카드ZERO Edition3(할인형)', '현대카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2646/card_img/39624/2646card_3.png', 15000, 15000, '전월실적 없음', '1.5만원 캐시백', @NOW, @NOW);
SET @card45 = LAST_INSERT_ID();

-- Card 46: 삼성카드 스페셜마일리지(스카이패스)
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('삼성카드 스페셜마일리지(스카이패스)', '삼성카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/54/card_img/20135/54card.png', 97000, 99000, '전월실적 없음', '기존회원도 최대 7.2만원 혜택', @NOW, @NOW);
SET @card46 = LAST_INSERT_ID();

-- Card 47: 카드의정석 I&U+
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('카드의정석 I&U+', '우리카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2688/card_img/33240/2688card.png', 12000, 12000, '전월실적 30 만원 이상', '최대 45.5만원 혜택', @NOW, @NOW);
SET @card47 = LAST_INSERT_ID();

-- Card 48: the OPUS silver
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('the OPUS silver', '우리카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2902/card_img/44665/2902card_1.png', 150000, 150000, '전월실적 50 만원 이상', '최대 57.5만원 혜택', @NOW, @NOW);
SET @card48 = LAST_INSERT_ID();

-- Card 49: American Express® Green Card Edition2
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('American Express® Green Card Edition2', '현대카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2662/card_img/32405/2662card.png', 0, 150000, '전월실적 50 만원 이상', '최대 25만원 캐시백', @NOW, @NOW);
SET @card49 = LAST_INSERT_ID();

-- Card 50: BC 바로 MACAO 카드
INSERT INTO cards (card_name, company, card_image_url, annual_fee_domestic, annual_fee_overseas, baseline_requirements_text, benefit_cap_summary, created_at, updated_at)
VALUES ('BC 바로 MACAO 카드', 'BC 바로카드', 'https://d1c5n4ri2guedi.cloudfront.net/card/2728/card_img/36134/2728card.png', 12000, 12000, '전월실적 30 만원 이상', '최대 25만원 혜택', @NOW, @NOW);
SET @card50 = LAST_INSERT_ID();

-- User1 -> Card1 (삼성 iD SELECT ALL), Card2 (신한 Mr.Life)
-- User2 -> Card7 (삼성카드 taptap O)
-- User3 -> Card4 (카드의정석 SHOPPING+)
INSERT INTO user_cards (registered_at, created_at, updated_at, card_id, user_id, card_number)
VALUES (@NOW, @NOW, @NOW, @card1, @uid1, '123456******7890');
SET @ucid1 = LAST_INSERT_ID();

INSERT INTO user_cards (registered_at, created_at, updated_at, card_id, user_id, card_number)
VALUES (@NOW, @NOW, @NOW, @card2, @uid1, '987654******3210');
SET @ucid2 = LAST_INSERT_ID();

INSERT INTO user_cards (registered_at, created_at, updated_at, card_id, user_id, card_number)
VALUES (@NOW, @NOW, @NOW, @card7, @uid2, '555666******1234');
SET @ucid3 = LAST_INSERT_ID();

INSERT INTO user_cards (registered_at, created_at, updated_at, card_id, user_id, card_number)
VALUES (@NOW, @NOW, @NOW, @card4, @uid3, '111222******5678');
SET @ucid4 = LAST_INSERT_ID();

-- -------------------------------------------------------------
-- 4. 카드 혜택 (card_benefits) - 실제 데이터
-- -------------------------------------------------------------

-- Card 1: 삼성 iD SELECT ALL 카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (50.00, NULL, @NOW, @NOW, @card1, @cat_digital);

-- Card 2: 신한카드 Mr.Life
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card2, @cat_bill);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card2, @cat_mart);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card2, @cat_conv);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card2, @cat_food);

-- Card 4: 카드의정석 SHOPPING+
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card4, @cat_online);

-- Card 6: KB국민 My WE:SH 카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card6, @cat_food);

-- Card 7: 삼성카드 taptap O
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (50.00, NULL, @NOW, @NOW, @card7, @cat_cafe);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card7, @cat_transport);

-- Card 8: LOCA 365 카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card8, @cat_bill);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card8, @cat_bill);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card8, @cat_transport);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card8, @cat_bill);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card8, @cat_online);

-- Card 10: KB Youth Club 체크카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (50.00, NULL, @NOW, @NOW, @card10, @cat_digital);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (50.00, NULL, @NOW, @NOW, @card10, @cat_digital);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (50.00, NULL, @NOW, @NOW, @card10, @cat_bill);

-- Card 11: 현대카드 M
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (5.00, NULL, @NOW, @NOW, @card11, @cat_food);

-- Card 13: 굿데이카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card13, @cat_bill);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card13, @cat_cafe);

-- Card 14: taptap DIGITAL
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (5.00, NULL, @NOW, @NOW, @card14, @cat_online);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (50.00, NULL, @NOW, @NOW, @card14, @cat_digital);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card14, @cat_conv);

-- Card 15: 삼성 iD SELECT ON 카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card15, @cat_food);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (50.00, NULL, @NOW, @NOW, @card15, @cat_digital);

-- Card 16: 카드의정석 EVERY DISCOUNT
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (2.00, NULL, @NOW, @NOW, @card16, @cat_online);

-- Card 17: 노리2 체크카드(KB Pay)
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card17, @cat_cafe);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card17, @cat_culture);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (5.00, NULL, @NOW, @NOW, @card17, @cat_beauty);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (5.00, NULL, @NOW, @NOW, @card17, @cat_conv);

-- Card 18: 신한카드 SOL트래블 체크
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (1.00, NULL, @NOW, @NOW, @card18, @cat_transport);

-- Card 19: 신한카드 처음(ANNIVERSE)
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (5.00, NULL, @NOW, @NOW, @card19, @cat_beauty);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (20.00, NULL, @NOW, @NOW, @card19, @cat_bill);

-- Card 20: 가온올림카드(실속형)
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (0.50, NULL, @NOW, @NOW, @card20, @cat_transport);

-- Card 21: 신한카드 Deep Oil
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card21, @cat_gas);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (5.00, NULL, @NOW, @NOW, @card21, @cat_cafe);

-- Card 22: 쿠팡 와우카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (4.00, NULL, @NOW, @NOW, @card22, @cat_online);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (1.20, NULL, @NOW, @NOW, @card22, @cat_online);

-- Card 24: LOCA LIKIT 1.2
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (1.50, NULL, @NOW, @NOW, @card24, @cat_online);

-- Card 25: 삼성 iD SIMPLE 카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (50.00, NULL, @NOW, @NOW, @card25, @cat_online);

-- Card 27: BC 바로 On&Off 카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card27, @cat_online);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card27, @cat_transport);

-- Card 28: 신한카드 Discount Plan+
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card28, @cat_cafe);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card28, @cat_online);

-- Card 29: 삼성 iD GLOBAL 카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (50.00, NULL, @NOW, @NOW, @card29, @cat_digital);

-- Card 30: 모빌리언스카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (1.00, NULL, @NOW, @NOW, @card30, @cat_online);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (8.00, NULL, @NOW, @NOW, @card30, @cat_conv);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (8.00, NULL, @NOW, @NOW, @card30, @cat_cafe);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (8.00, NULL, @NOW, @NOW, @card30, @cat_food);

-- Card 31: WE:SH Travel
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card31, @cat_cafe);

-- Card 33: 올바른 FLEX 카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (50.00, NULL, @NOW, @NOW, @card33, @cat_cafe);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (20.00, NULL, @NOW, @NOW, @card33, @cat_digital);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (30.00, NULL, @NOW, @NOW, @card33, @cat_culture);

-- Card 34: 굿데이올림카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card34, @cat_bill);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card34, @cat_mart);

-- Card 38: 신한카드 The CLASSIC-S
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (2.00, NULL, @NOW, @NOW, @card38, @cat_travel);

-- Card 39: 우리카드 7CORE
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card39, @cat_online);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card39, @cat_mart);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card39, @cat_cafe);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card39, @cat_online);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card39, @cat_edu);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card39, @cat_health);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card39, @cat_gas);

-- Card 40: 현대카드 ZERO Up
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (1.60, NULL, @NOW, @NOW, @card40, @cat_online);

-- Card 43: 네이버페이 머니카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (1.50, NULL, @NOW, @NOW, @card43, @cat_online);

-- Card 47: 카드의정석 I&U+
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card47, @cat_transport);

-- Card 48: the OPUS silver
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (3.00, NULL, @NOW, @NOW, @card48, @cat_travel);
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card48, @cat_digital);

-- Card 50: BC 바로 MACAO 카드
INSERT INTO card_benefits (benefit_rate, benefit_limit, created_at, updated_at, card_id, category_id)
VALUES (10.00, NULL, @NOW, @NOW, @card50, @cat_gas);

-- =============================================================
-- 4.5. 구독 서비스 (subscriptions) - 실제 서비스 데이터
-- =============================================================

-- User1 (한정수) 구독 서비스 - 5개
INSERT INTO subscriptions (service_name, monthly_fee, next_billing, status, created_at, updated_at, user_id, user_card_id, category_id)
VALUES
  ('Netflix',           14900, '2026-02-10', 'ACTIVE', @NOW, @NOW, @uid1, @ucid2, @cat_digital),
  ('YouTube Premium',   14900, '2026-02-05', 'ACTIVE', @NOW, @NOW, @uid1, @ucid2, @cat_digital),
  ('Spotify',           10900, '2026-02-15', 'ACTIVE', @NOW, @NOW, @uid1, @ucid2, @cat_digital),
  ('ChatGPT Plus',      28000, '2026-02-13', 'ACTIVE', @NOW, @NOW, @uid1, @ucid2, @cat_digital),
  ('쿠팡 로켓와우',      7890, '2026-02-20', 'ACTIVE', @NOW, @NOW, @uid1, @ucid2, @cat_online);

-- User2 (김테스트) 구독 서비스 - 4개
INSERT INTO subscriptions (service_name, monthly_fee, next_billing, status, created_at, updated_at, user_id, user_card_id, category_id)
VALUES
  ('Netflix',           14900, '2026-02-05', 'ACTIVE', @NOW, @NOW, @uid2, @ucid3, @cat_digital),
  ('YouTube Premium',   14900, '2026-02-05', 'ACTIVE', @NOW, @NOW, @uid2, @ucid3, @cat_digital),
  ('Apple Music',       10900, '2026-02-05', 'ACTIVE', @NOW, @NOW, @uid2, @ucid3, @cat_digital),
  ('왓챠',               7900, '2026-02-05', 'ACTIVE', @NOW, @NOW, @uid2, @ucid3, @cat_digital);

-- User3 (박샘플) 구독 서비스 - 3개
INSERT INTO subscriptions (service_name, monthly_fee, next_billing, status, created_at, updated_at, user_id, user_card_id, category_id)
VALUES
  ('멜론',              10900, '2026-02-01', 'ACTIVE', @NOW, @NOW, @uid3, @ucid4, @cat_digital),
  ('티빙',              13900, '2026-02-10', 'ACTIVE', @NOW, @NOW, @uid3, @ucid4, @cat_digital),
  ('네이버플러스 멤버십', 4900, '2026-02-25', 'ACTIVE', @NOW, @NOW, @uid3, @ucid4, @cat_online);

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
  (13500, '코스트코 양재점',     '2025-08-28 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid1, @ucid1, 0,0,0,0,0),
  (6000,  '할리스커피',           '2025-08-30 10:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0);

-- ── 2025년 9월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (7500,  '김밥천국 강남점',     '2025-09-01 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (5000,  '스타벅스 테헤란로',   '2025-09-03 09:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-09-03 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (15000, '배달의민족 치킨',     '2025-09-04 19:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (2100,  'GS25 선릉점',         '2025-09-05 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (30000, 'Gmarket',             '2025-09-07 21:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (9000,  '본죽 역삼점',         '2025-09-08 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (55000, 'SK텔레콤',           '2025-09-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid1, @ucid1, 0,0,0,0,0),
  (6000,  '투썸플레이스',         '2025-09-11 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-09-12 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (11000, '맘스터치 선릉점',     '2025-09-14 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (18000, '롯데시네마 강남',     '2025-09-15 18:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid1, @ucid1, 0,0,0,0,0),
  (2500,  'CU 역삼역점',         '2025-09-16 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (12000, '버거킹 강남역점',     '2025-09-18 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (52000, 'SK에너지 서초주유소', '2025-09-19 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-09-20 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (5500,  '이디야커피',           '2025-09-21 10:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (12000, '알라딘 중고서점',     '2025-09-22 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid1, @ucid1, 0,0,0,0,0),
  (45000, '세브란스병원',         '2025-09-23 14:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid1, @ucid1, 0,0,0,0,0),
  (8500,  '다이소 강남점',       '2025-09-24 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid1, @ucid1, 0,0,0,0,0),
  (14900, 'Netflix',             '2025-09-25 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid1, @ucid2, 0,0,0,0,0),
  (1800,  'GS25 선릉점',         '2025-09-26 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-09-27 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (18000, 'E마트 강남점',       '2025-09-28 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid1, @ucid1, 0,0,0,0,0),
  (7000,  '스타벅스 테헤란로',   '2025-09-29 10:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0);

-- ── 2025년 10월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (9000,  '설빙 강남점',         '2025-10-01 14:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-10-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (8000,  '김밥천국 강남점',     '2025-10-02 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (18000, '배달의민족 족발',     '2025-10-04 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (2500,  'CU 역삼역점',         '2025-10-05 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (45000, '쿠팡',               '2025-10-06 21:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (10000, '죽이야기 역삼점',     '2025-10-07 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (55000, 'SK텔레콤',           '2025-10-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid1, @ucid1, 0,0,0,0,0),
  (6500,  '할리스커피',           '2025-10-11 10:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-10-12 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (13000, '롯데리아 선릉점',     '2025-10-14 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (20000, 'CGV 강남',           '2025-10-15 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid1, @ucid1, 0,0,0,0,0),
  (3000,  'GS25 선릉점',         '2025-10-16 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (14000, '맥도날드 역삼점',     '2025-10-18 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (58000, 'SK에너지 서초주유소', '2025-10-19 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-10-20 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (6000,  '투썸플레이스',         '2025-10-21 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (15000, 'YES24',               '2025-10-22 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid1, @ucid1, 0,0,0,0,0),
  (30000, '약국 강남점',         '2025-10-23 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid1, @ucid1, 0,0,0,0,0),
  (9500,  '올리브영 강남점',     '2025-10-24 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid1, @ucid1, 0,0,0,0,0),
  (14900, 'Netflix',             '2025-10-25 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid1, @ucid2, 0,0,0,0,0),
  (2000,  'CU 역삼역점',         '2025-10-26 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-10-27 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (22000, '코스트코 양재점',     '2025-10-28 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid1, @ucid1, 0,0,0,0,0),
  (7500,  '스타벅스 테헤란로',   '2025-10-30 10:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0);

-- ── 2025년 11월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (9500,  '김밥천국 강남점',     '2025-11-01 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (5500,  '스타벅스 테헤란로',   '2025-11-02 09:10:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-11-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (15000, '배달의민족 피자',     '2025-11-04 19:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (2300,  'GS25 선릉점',         '2025-11-05 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (35000, 'Auction',             '2025-11-06 21:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (11000, '본죽 역삼점',         '2025-11-07 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (55000, 'SK텔레콤',           '2025-11-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid1, @ucid1, 0,0,0,0,0),
  (6500,  '투썸플레이스',         '2025-11-11 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-11-12 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (12000, '한솥도시락 선릉점',   '2025-11-14 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (16000, '메가박스 강남',       '2025-11-15 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid1, @ucid1, 0,0,0,0,0),
  (2800,  'CU 역삼역점',         '2025-11-16 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (13000, '서브웨이 역삼점',     '2025-11-18 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (54000, 'GS칼텍스 강남주유소', '2025-11-19 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-11-20 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (5500,  '이디야커피',           '2025-11-21 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (11000, '교보문고',           '2025-11-22 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid1, @ucid1, 0,0,0,0,0),
  (40000, '약국 강남점',         '2025-11-23 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid1, @ucid1, 0,0,0,0,0),
  (8000,  '올리브영 강남점',     '2025-11-24 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid1, @ucid1, 0,0,0,0,0),
  (14900, 'Netflix',             '2025-11-25 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid1, @ucid2, 0,0,0,0,0),
  (2100,  'GS25 선릉점',         '2025-11-26 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-11-27 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (20000, 'E마트 강남점',       '2025-11-28 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid1, @ucid1, 0,0,0,0,0),
  (8000,  '할리스커피',           '2025-11-29 10:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0);

-- ── 2025년 12월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (10000, '김밥천국 강남점',     '2025-12-01 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (6000,  '스타벅스 테헤란로',   '2025-12-02 09:10:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (20000, '배달의민족 중식',     '2025-12-04 19:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (2500,  'CU 역삼역점',         '2025-12-05 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (50000, '쿠팡',               '2025-12-06 21:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (12000, '본죽 역삼점',         '2025-12-07 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (55000, 'SK텔레콤',           '2025-12-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid1, @ucid1, 0,0,0,0,0),
  (7000,  '투썸플레이스',         '2025-12-11 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-12 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (13000, '한솥도시락 선릉점',   '2025-12-14 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (18000, 'CGV 강남',           '2025-12-15 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid1, @ucid1, 0,0,0,0,0),
  (3000,  'GS25 선릉점',         '2025-12-16 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (14000, '버거킹 강남역점',     '2025-12-18 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (60000, 'SK에너지 서초주유소', '2025-12-19 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-20 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (6500,  '이디야커피',           '2025-12-21 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (13000, '교보문고',           '2025-12-22 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid1, @ucid1, 0,0,0,0,0),
  (35000, '약국 강남점',         '2025-12-23 11:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid1, @ucid1, 0,0,0,0,0),
  (10000, '올리브영 강남점',     '2025-12-24 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid1, @ucid1, 0,0,0,0,0),
  (14900, 'Netflix',             '2025-12-25 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid1, @ucid2, 0,0,0,0,0),
  (2200,  'CU 역삼역점',         '2025-12-26 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-27 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (25000, '코스트코 양재점',     '2025-12-28 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid1, @ucid1, 0,0,0,0,0),
  (8500,  '스타벅스 테헤란로',   '2025-12-30 10:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0);

-- ── 2026년 1월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (11000, '김밥천국 강남점',     '2026-01-02 12:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (6500,  '스타벅스 테헤란로',   '2026-01-03 09:10:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-03 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (18000, '배달의민족 한식',     '2026-01-04 19:30:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (2600,  'GS25 선릉점',         '2026-01-05 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (40000, 'Gmarket',             '2026-01-06 21:00:00', 0, 'PAID', @NOW, @NOW, @cat_online,   @uid1, @ucid2, 0,0,0,0,0),
  (13000, '본죽 역삼점',         '2026-01-07 12:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (55000, 'SK텔레콤',           '2026-01-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_bill,    @uid1, @ucid1, 0,0,0,0,0),
  (7500,  '투썸플레이스',         '2026-01-11 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-12 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (14000, '한솥도시락 선릉점',   '2026-01-14 12:20:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (17000, '롯데시네마 강남',     '2026-01-15 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid1, @ucid1, 0,0,0,0,0),
  (3200,  'CU 역삼역점',         '2026-01-16 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (15000, '맥도날드 역삼점',     '2026-01-18 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid1, @ucid1, 0,0,0,0,0),
  (62000, 'GS칼텍스 강남주유소', '2026-01-19 10:00:00', 0, 'PAID', @NOW, @NOW, @cat_gas,     @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-20 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (7000,  '할리스커피',           '2026-01-21 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid1, @ucid1, 0,0,0,0,0),
  (14000, 'YES24',               '2026-01-22 16:00:00', 0, 'PAID', @NOW, @NOW, @cat_edu,      @uid1, @ucid1, 0,0,0,0,0),
  (38000, '세브란스병원',         '2026-01-23 14:00:00', 0, 'PAID', @NOW, @NOW, @cat_health,   @uid1, @ucid1, 0,0,0,0,0),
  (11000, '다이소 강남점',       '2026-01-24 17:30:00', 0, 'PAID', @NOW, @NOW, @cat_beauty,   @uid1, @ucid1, 0,0,0,0,0),
  (14900, 'Netflix',             '2026-01-25 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid1, @ucid2, 0,0,0,0,0),
  (2300,  'GS25 선릉점',         '2026-01-26 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid1, @ucid1, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-27 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid1, @ucid1, 0,0,0,0,0),
  (23000, 'E마트 강남점',       '2026-01-28 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid1, @ucid1, 0,0,0,0,0);

-- =============================================================
-- 6. User2 (김테스트) : 2개월치 (2025-12 ~ 2026-01)
--    주력: 교통 / 편의점, Card2(삼성) 단독
-- =============================================================

-- ── 2025년 12월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (1250,  '서울교통공사',         '2025-12-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (2500,  'CU 강남점',           '2025-12-03 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (7000,  '맘스터치 강남점',     '2025-12-05 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-06 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (3000,  'GS25 테헤란로점',     '2025-12-09 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (12000, 'Spotify Premium',     '2025-12-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-12 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (2800,  'CU 강남점',           '2025-12-13 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (15000, '배달의민족 치킨',     '2025-12-14 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-16 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (2600,  'GS25 테헤란로점',     '2025-12-18 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (9000,  '스타벅스',             '2025-12-20 10:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid2, @ucid3, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-21 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (3100,  'CU 강남점',           '2025-12-23 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (13000, 'CGV 강남',           '2025-12-25 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2025-12-27 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (2900,  'GS25 테헤란로점',     '2025-12-28 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0);

-- ── 2026년 1월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (1250,  '서울교통공사',         '2026-01-02 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (2700,  'CU 강남점',           '2026-01-03 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (8000,  '버거킹 강남점',       '2026-01-05 13:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-06 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (3200,  'GS25 테헤란로점',     '2026-01-08 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (12000, 'Spotify Premium',     '2026-01-10 00:00:00', 0, 'PAID', @NOW, @NOW, @cat_digital,  @uid2, @ucid3, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-12 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (2900,  'CU 강남점',           '2026-01-13 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (16000, '배달의민족 족발',     '2026-01-14 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_food,    @uid2, @ucid3, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-16 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (2800,  'GS25 테헤란로점',     '2026-01-18 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (10000, '할리스커피',           '2026-01-20 10:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid2, @ucid3, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-21 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (3000,  'CU 강남점',           '2026-01-23 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0),
  (14000, '메가박스 강남',       '2026-01-25 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid2, @ucid3, 0,0,0,0,0),
  (1250,  '서울교통공사',         '2026-01-27 08:30:00', 0, 'PAID', @NOW, @NOW, @cat_transport,@uid2, @ucid3, 0,0,0,0,0),
  (3100,  'GS25 테헤란로점',     '2026-01-28 22:10:00', 0, 'PAID', @NOW, @NOW, @cat_conv,    @uid2, @ucid3, 0,0,0,0,0);

-- =============================================================
-- 7. User3 (박샘플) : 2개월치 (2025-12 ~ 2026-01)
--    주력: 대형마트 / 문화여가, Card3(현대) 단독
-- =============================================================

-- ── 2025년 12월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (28000, 'E마트 강남점',       '2025-12-05 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (15000, '메가박스 강남',       '2025-12-07 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid3, @ucid4, 0,0,0,0,0),
  (8000,  '스타벅스',             '2025-12-10 10:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (32000, '코스트코 양재점',     '2025-12-12 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (12000, 'CGV 강남',           '2025-12-14 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid3, @ucid4, 0,0,0,0,0),
  (6500,  '투썸플레이스',         '2025-12-17 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (25000, '홈플러스 강남점',     '2025-12-19 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (18000, '롯데시네마 강남',     '2025-12-21 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid3, @ucid4, 0,0,0,0,0),
  (7000,  '이디야커피',           '2025-12-23 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (30000, 'E마트 강남점',       '2025-12-26 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (14000, '메가박스 강남',       '2025-12-28 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid3, @ucid4, 0,0,0,0,0);

-- ── 2026년 1월 ──
INSERT INTO expenses
  (amount, merchant_name, spent_at, benefit_received, status, created_at, updated_at, category_id, user_id, user_card_id, after_payment_balance, earn_point, fee, installment_month, payment_principal)
VALUES
  (27000, '코스트코 양재점',     '2026-01-02 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (16000, 'CGV 강남',           '2026-01-04 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid3, @ucid4, 0,0,0,0,0),
  (9000,  '스타벅스',             '2026-01-07 10:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (35000, 'E마트 강남점',       '2026-01-09 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (13000, '롯데시네마 강남',     '2026-01-11 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid3, @ucid4, 0,0,0,0,0),
  (7500,  '할리스커피',           '2026-01-14 14:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (28000, '홈플러스 강남점',     '2026-01-16 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (19000, '메가박스 강남',       '2026-01-18 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid3, @ucid4, 0,0,0,0,0),
  (8000,  '투썸플레이스',         '2026-01-21 15:00:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0),
  (32000, '코스트코 양재점',     '2026-01-23 17:00:00', 0, 'PAID', @NOW, @NOW, @cat_mart,    @uid3, @ucid4, 0,0,0,0,0),
  (15000, 'CGV 강남',           '2026-01-25 19:00:00', 0, 'PAID', @NOW, @NOW, @cat_culture,  @uid3, @ucid4, 0,0,0,0,0),
  (9500,  '이디야커피',           '2026-01-28 10:30:00', 0, 'PAID', @NOW, @NOW, @cat_cafe,    @uid3, @ucid4, 0,0,0,0,0);

-- =============================================================
-- END OF SEED SCRIPT
-- Summary: 50 real cards, 3 users, 4 user_cards, 69 card_benefits, ~360 expenses (6 months)
-- =============================================================
