from django.urls import path
from . import views

app_name = 'codef'

urlpatterns = [
    path('token/', views.GetCodefTokenView.as_view(), name='get_codef_token'),
    path('connected-id/create/', views.CreateConnectedIdView.as_view(), name='create_connected_id'),
    path('card/list/', views.GetCardListView.as_view(), name='get_card_list'),
    path('card/billing/', views.GetBillingListView.as_view(), name='get_billing_list'),
    path('card/approval/', views.GetApprovalListView.as_view(), name='get_approval_list'),
]
