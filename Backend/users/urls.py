from django.urls import path

from users.views import SignUpView, LoginView, UserProfileView

app_name = 'users'

urlpatterns = [
    path('signup', SignUpView.as_view(), name='signup'),
    path('login', LoginView.as_view(), name='login'),
    path('', UserProfileView.as_view(), name='user-profile'),
]
