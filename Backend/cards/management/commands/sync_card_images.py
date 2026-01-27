import csv
import os
from django.conf import settings
from django.core.management.base import BaseCommand
from cards.models import Card


class Command(BaseCommand):
    help = 'card_gorilla_list.csv에서 카드이름과 이미지URL을 매칭해 DB의 card_image_url을 업데이트합니다.'

    def handle(self, *args, **options):
        # BASE_DIR을 사용하여 파일 경로 설정 (로컬/Docker 모두 호환)
        file_path = os.path.join(settings.BASE_DIR, 'card_gorilla_list.csv')
        
        # 만약 settings.BASE_DIR에 없으면 절대 경로 하드코딩 (Docker fallback)
        if not os.path.exists(file_path):
             file_path = '/app/card_gorilla_list.csv'

        updated_count = 0
        not_found_count = 0
        
        try:
            with open(file_path, 'r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                
                for row in reader:
                    card_name = row.get('카드명', '').strip()
                    image_url = row.get('이미지URL', '').strip()
                    
                    if not card_name or not image_url:
                        continue
                    
                    # 카드명으로 DB에서 찾기
                    try:
                        card = Card.objects.get(card_name=card_name)
                        card.card_image_url = image_url
                        card.save()
                        updated_count += 1
                        self.stdout.write(f"✓ {card_name} - 이미지 URL 업데이트")
                    except Card.DoesNotExist:
                        not_found_count += 1
                        self.stdout.write(self.style.WARNING(f"✗ {card_name} - DB에 없음"))
                
                self.stdout.write(self.style.SUCCESS(
                    f"\n완료: {updated_count}개 업데이트, {not_found_count}개 미매칭"
                ))
                
        except FileNotFoundError:
            self.stdout.write(self.style.ERROR(f"파일을 찾을 수 없습니다: {file_path}"))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"에러: {e}"))
