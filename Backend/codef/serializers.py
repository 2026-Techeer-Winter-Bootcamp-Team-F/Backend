from rest_framework import serializers


class ConnectedIdSerializer(serializers.Serializer):
    """
    Connected ID 발급 요청 시리얼라이저
    
    카드사 계정 정보를 입력받아 Codef API를 통해 connected ID를 발급받기 위한 시리얼라이저
    """
    organization = serializers.CharField(
        max_length=50,
        required=True,
        help_text="카드사 코드 (예: 0304)",
        example="0304"
    )
    card_id = serializers.CharField(
        max_length=100,
        required=True,
        help_text="카드사 회원 ID",
        example="kh1931"
    )
    password = serializers.CharField(
        max_length=100,
        required=True,
        write_only=True,
        help_text="카드사 회원 비밀번호",
        example="password123"
    )
    card_no = serializers.CharField(
        max_length=50,
        required=False,
        allow_blank=True,
        help_text="카드 번호 (선택)",
        example="1234567890123456"
    )
    card_password = serializers.CharField(
        max_length=50,
        required=False,
        allow_blank=True,
        write_only=True,
        help_text="카드 비밀번호 (선택)",
        example="1234"
    )

    def validate_organization(self, value):
        """organization 필드 유효성 검사"""
        if not value.strip():
            raise serializers.ValidationError("카드사 코드(organization)는 비어있을 수 없습니다.")
        return value

    def validate_card_id(self, value):
        """card_id 필드 유효성 검사"""
        if not value.strip():
            raise serializers.ValidationError("카드사 회원 ID(card_id)는 비어있을 수 없습니다.")
        return value

    def validate_password(self, value):
        """password 필드 유효성 검사"""
        if not value.strip():
            raise serializers.ValidationError("카드사 회원 비밀번호(password)는 비어있을 수 없습니다.")
        return value


class ConnectedIdResponseSerializer(serializers.Serializer):
    """Connected ID 발급 성공 응답 시리얼라이저"""
    success = serializers.BooleanField(example=True)
    connected_id = serializers.CharField(example="CONN_ID_12345")
    message = serializers.CharField(example="Connected ID가 발급되었습니다.")


class CodefTokenSerializer(serializers.Serializer):
    """Codef API 토큰 발급 응답 시리얼라이저"""
    success = serializers.BooleanField(example=True)
    access_token = serializers.CharField(example="eyJ0eXAiOiJKV1QiLCJhbGc...")
    token_type = serializers.CharField(example="Bearer")
    message = serializers.CharField(example="토큰이 발급되었습니다.")


class ErrorResponseSerializer(serializers.Serializer):
    """에러 응답 시리얼라이저"""
    success = serializers.BooleanField(example=False)
    error_message = serializers.CharField(example="에러 메시지")
