from django.urls import path
from .views import MakeChatRoomView, SendMessageView, ChatView

app_name = "chat" 

urlpatterns = [
    path("make_room/", MakeChatRoomView.as_view(), name="make_chat_room"),
    path("send_message/", SendMessageView.as_view(), name="send_message"),
    path("api/chat/", ChatView.as_view(), name="chat_api"),
]