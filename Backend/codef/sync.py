import logging
from typing import List, Dict, Tuple
from django.db import transaction
from cards.models import Card
from users.models import UserCard
from .service import CodefAPIService

logger = logging.getLogger(__name__)


class CardSyncManager:
    """사용자 카드 정보를 Codef API에서 가져와 DB와 동기화하는 매니저 클래스"""
    
    @staticmethod
    @transaction.atomic
    def sync_user_cards_from_codef(
        user,
        codef_user_id: str,
        codef_password: str,
        codef_connection_id: str = None
    ) -> Tuple[bool, Dict]:
        """
        사용자의 카드 정보를 Codef API에서 조회하여 DB에 저장/업데이트
        
        Args:
            user: Django User 객체
            codef_user_id (str): Codef 사용자 ID
            codef_password (str): Codef 사용자 비밀번호
            codef_connection_id (str, optional): Codef 연결 ID (재인증 시)
        
        Returns:
            Tuple[bool, Dict]: (성공 여부, 결과 데이터)
                - 성공: (True, {"cards_added": int, "cards_updated": int, "cards": List})
                - 실패: (False, {"error": str})
        """
        try:
            # 1. Codef API에서 카드 정보 조회
            codef_service = CodefAPIService()
            api_response = codef_service.fetch_user_cards(
                codef_user_id,
                codef_password,
                codef_connection_id
            )
            
            if not api_response.get('success'):
                error_msg = api_response.get('error_message', 'Unknown error')
                logger.error(f"Failed to fetch cards from Codef: {error_msg}")
                return False, {"error": error_msg}
            
            codef_cards = api_response.get('data', [])
            
            if not codef_cards:
                logger.warning(f"No cards found for user {user.id}")
                return True, {
                    "cards_added": 0,
                    "cards_updated": 0,
                    "cards": []
                }
            
            # 2. 카드 정보 DB에 저장/업데이트
            cards_added = 0
            cards_updated = 0
            saved_cards = []
            
            for codef_card in codef_cards:
                try:
                    # Codef 데이터를 우리 모델에 맞게 파싱
                    parsed_data = codef_service.parse_card_data(codef_card)
                    
                    # 카드명과 발급사 기반으로 기존 카드 조회 (중복 방지)
                    card, created = Card.objects.get_or_create(
                        card_name=parsed_data['card_name'],
                        company=parsed_data['company'],
                        defaults=parsed_data
                    )
                    
                    if created:
                        cards_added += 1
                        logger.info(f"New card created: {card.card_name}")
                    else:
                        # 기존 카드 정보 업데이트
                        for key, value in parsed_data.items():
                            if key not in ['card_name', 'company']:
                                setattr(card, key, value)
                        card.save()
                        cards_updated += 1
                        logger.info(f"Card updated: {card.card_name}")
                    
                    # 3. UserCard 연결 (사용자와 카드 매핑)
                    card_number = codef_card.get('cardNumber', '')
                    user_card, uc_created = UserCard.objects.get_or_create(
                        user=user,
                        card=card,
                        defaults={'card_number': card_number}
                    )
                    
                    if not uc_created and user_card.card_number != card_number:
                        # 카드 번호 업데이트
                        user_card.card_number = card_number
                        user_card.save()
                    
                    saved_cards.append({
                        "card_id": card.card_id,
                        "card_name": card.card_name,
                        "company": card.company,
                        "newly_added": created
                    })
                    
                except Exception as e:
                    logger.error(f"Error processing card {codef_card.get('cardName', 'Unknown')}: {str(e)}")
                    # 하나의 카드 처리 실패해도 다른 카드는 계속 진행
                    continue
            
            logger.info(f"Card sync completed: {cards_added} added, {cards_updated} updated")
            
            return True, {
                "cards_added": cards_added,
                "cards_updated": cards_updated,
                "cards": saved_cards
            }
        
        except Exception as e:
            logger.error(f"Unexpected error in sync_user_cards_from_codef: {str(e)}")
            return False, {"error": f"Unexpected error: {str(e)}"}
    
    @staticmethod
    def get_user_cards(user) -> List[Card]:
        """
        사용자가 보유한 모든 카드를 DB에서 조회
        
        Args:
            user: Django User 객체
        
        Returns:
            List[Card]: 사용자의 카드 목록
        """
        try:
            user_cards = UserCard.objects.filter(user=user).select_related('card')
            cards = [uc.card for uc in user_cards]
            logger.info(f"Retrieved {len(cards)} cards for user {user.id}")
            return cards
        except Exception as e:
            logger.error(f"Error retrieving user cards: {str(e)}")
            return []
