import os
import django
import random
from datetime import datetime
from django.utils import timezone

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from users.models import User, UserCard
from expense.models import Expense
from category.models import Category
from cards.models import Card

def create_sample_category():
    cats = ['식비', '교통', '쇼핑', '카페', '편의점']
    created_cats = []
    for c_name in cats:
        # Category model uses 'category_name'
        cat, created = Category.objects.get_or_create(category_name=c_name)
        created_cats.append(cat)
    return created_cats

def ensure_user_card(user):
    # 유처에게 연결된 카드가 있는지 확인, 없으면 생성
    if UserCard.objects.filter(user=user).exists():
        return UserCard.objects.filter(user=user).first()
    
    # 카드 마스터 데이터가 필요함
    card = Card.objects.first()
    if not card: 
         # 카드가 없으면 더미 카드 생성
         card = Card.objects.create(
             card_name="Test Card",
             company="Test Bank"
         )
         print(" - [알림] 테스트용 기본 카드(Card) 데이터 생성됨")
        
    # 만약 카드가 있다면 UserCard 생성
    if card:
         # UserCard model fields: user, card, card_number
         uc = UserCard.objects.create(
             user=user,
             card=card,
             card_number="1234-5678-0000-0000"
         )
         print(" - [알림] 유저 카드(UserCard) 생성됨")
         return uc
    
    return None

def create_dummy_data(user):
    print(f"\n>> [데이터 생성] '{user.name}' ({user.email}) 님을 위한 테스트 데이터를 생성합니다...")
    categories = create_sample_category()
    
    # UserCard 확인
    user_card = ensure_user_card(user)
    if not user_card:
        print("!! UserCard 생성 실패. Expense를 만들 수 없습니다.")
        return

    # 2026-01-22 기준
    # Make sure timezone is aware if settings use TZ
    now = timezone.now()
    # Force year to 2026 for testing as per user request context
    current_year = 2026
    current_month = 1

    samples = [
        ("스타벅스", 4500, "카페"),
        ("GS25", 3500, "편의점"),
        ("카카오택시", 12800, "교통"),
        ("쿠팡", 28500, "쇼핑"),
        ("김밥천국", 7500, "식비"),
        ("배달의민족", 24000, "식비"),
        ("올리브영", 15000, "쇼핑"),
        ("지하철", 1400, "교통"),
    ]
    
    count = 0
    for i in range(15): # 15개 생성
        merch, amt, cat_name = random.choice(samples)
        # Find category by category_name
        cat = next((c for c in categories if c.category_name == cat_name), None)
        
        # 1월 내 랜덤 날짜
        rand_day = random.randint(1, 22)
        # Create timezone-aware datetime if possible, or naive
        try:
            spent_date = timezone.datetime(current_year, current_month, rand_day, 
                                          random.randint(9, 21), random.randint(0, 59), 
                                          tzinfo=timezone.get_current_timezone())
        except:
            spent_date = datetime(current_year, current_month, rand_day, 
                                  random.randint(9, 21), random.randint(0, 59))
        
        try:
            Expense.objects.create(
                user=user,
                amount=amt,
                merchant_name=merch,
                spent_at=spent_date,
                category=cat,
                user_card=user_card,
                payment_type="일시불",
                status="PAID"
            )
            count += 1
        except Exception as e:
            print(f" 생성 실패: {e}")
            # If failing, might be missing required fields. Stop to inspect.
            break

    if count > 0:
        print(f">> {count}개의 지출 내역이 생성되었습니다. 앱에서 '새로고침' 버튼을 눌러보세요.")
    else:
        print(">> 지출 내역 생성에 실패했습니다.")

def check_data():
    print("--- [데이터베이스 상태 점검] ---")
    
    # 1. 유저 확인
    users = User.objects.all()
    if not users.exists():
        print("!! 유저가 없습니다. 앱에서 회원가입부터 진행해주세요.")
        return

    first_user = users.first()
    print(f"등록된 유저 수: {users.count()}")
    for u in users:
        print(f" - User: {u.email} (Name: {u.name})")

    # 2. 카테고리 확인
    print(f"\n등록된 카테고리 수: {Category.objects.count()}")

    # 3. 전체 지출 이력 확인
    total_expenses = Expense.objects.count()
    print(f"전체 지출 내역 수: {total_expenses}")
    
    # 4. 조회 대상 확인 (2026년 1월)
    target_year = 2026
    target_month = 1
    
    monthly_expenses = Expense.objects.filter(
        spent_at__year=target_year, 
        spent_at__month=target_month
    )
    
    print(f"\n[{target_year}년 {target_month}월 데이터 점검]")
    print(f" - 해당 월 지출 내역 수: {monthly_expenses.count()}")
    
    if monthly_expenses.count() == 0:
        print(" >> 현재 이 달의 데이터가 없습니다.")
        print(" >> 테스트를 위해 데이터를 자동으로 생성합니다...")
        create_dummy_data(first_user)
    else:
        print(" >> 데이터가 존재합니다 (상위 5개):")
        for ex in monthly_expenses[:5]:
            print(f"   [{ex.spent_at.date()}] {ex.merchant_name} : {ex.amount}원 ({ex.user.name})")

if __name__ == "__main__":
    check_data()
