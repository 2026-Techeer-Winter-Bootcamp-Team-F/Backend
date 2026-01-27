import os
import django
import sys

# Set up Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from users.models import User

# Print header
print(f"{'ID':<5} {'Email':<30} {'Name':<20} {'Created At'}")
print("-" * 80)

# Fetch and print users
try:
    for user in User.objects.all().order_by('-created_at'):
        print(f"{user.user_id:<5} {user.email:<30} {user.name:<20} {user.created_at}")
except Exception as e:
    print(f"Error extracting data: {e}")
