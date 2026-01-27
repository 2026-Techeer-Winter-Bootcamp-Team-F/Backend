import requests
import json

BASE_URL = "http://localhost:80/api/v1"

def test_flow():
    # 1. Signup
    email = "testgpt@example.com"
    password = "password123"
    name = "GPT Test"
    
    print("1. Signup...")
    signup_data = {"email": email, "password": password, "name": name}
    try:
        resp = requests.post(f"{BASE_URL}/users/signup", json=signup_data)
        print(f"Signup Status: {resp.status_code}")
        print(f"Signup Response: {resp.text}")
    except Exception as e:
        print(f"Signup failed: {e}")

    # 2. Login
    print("\n2. Login...")
    login_data = {"email": email, "password": password}
    resp = requests.post(f"{BASE_URL}/users/login", json=login_data)
    print(f"Login Status: {resp.status_code}")
    if resp.status_code != 200:
        print("Login failed, cannot proceed.")
        return

    tokens = resp.json().get('token')
    access_token = tokens['access']
    print("Got Access Token.")

    # 3. Chat
    print("\n3. Chat...")
    headers = {"Authorization": f"Bearer {access_token}"}
    chat_data = {"message": "Hello, how are you?"}
    
    resp = requests.post(f"{BASE_URL}/chat/api/chat/", json=chat_data, headers=headers)
    print(f"Chat Status: {resp.status_code}")
    print(f"Chat Response: {resp.text}")

if __name__ == "__main__":
    test_flow()
