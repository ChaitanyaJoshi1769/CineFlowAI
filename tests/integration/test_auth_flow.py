"""Integration tests for authentication flow"""
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_user_registration_and_login():
    """Test complete registration and login flow"""
    client = AsyncClient(base_url="http://localhost:8000")
    
    # Register user
    register_resp = await client.post("/api/v1/auth/register", json={
        "email": "test@example.com",
        "password": "SecurePassword123!",
        "first_name": "Test",
        "last_name": "User"
    })
    assert register_resp.status_code == 201
    data = register_resp.json()
    assert data["success"] == True
    assert "access_token" in data["data"]
    
    # Login with credentials
    login_resp = await client.post("/api/v1/auth/login", json={
        "email": "test@example.com",
        "password": "SecurePassword123!"
    })
    assert login_resp.status_code == 200
    login_data = login_resp.json()
    assert login_data["success"] == True
    assert "access_token" in login_data["data"]
    
    # Verify token
    token = login_data["data"]["access_token"]
    verify_resp = await client.post("/api/v1/auth/verify", json={
        "token": token
    })
    assert verify_resp.status_code == 200
    verify_data = verify_resp.json()
    assert verify_data["success"] == True
    assert verify_data["data"]["valid"] == True

@pytest.mark.asyncio
async def test_unauthorized_access():
    """Test that unauthorized requests are rejected"""
    client = AsyncClient(base_url="http://localhost:8000")
    
    resp = await client.get("/api/v1/users")
    assert resp.status_code == 401
