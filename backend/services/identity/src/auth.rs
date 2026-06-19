use jsonwebtoken::{encode, decode, Header, EncodingKey, DecodingKey, Validation};
use chrono::Utc;
use crate::models::JwtClaims;
use uuid::Uuid;

/// Create JWT token
pub fn create_token(user_id: &Uuid, email: &str, secret: &str) -> Result<(String, String), String> {
    let now = Utc::now();
    let iat = now.timestamp();
    let exp = (now + chrono::Duration::hours(24)).timestamp();

    let access_claims = JwtClaims {
        sub: user_id.to_string(),
        email: email.to_string(),
        iat,
        exp,
    };

    let refresh_exp = (now + chrono::Duration::days(30)).timestamp();
    let refresh_claims = JwtClaims {
        sub: user_id.to_string(),
        email: email.to_string(),
        iat,
        exp: refresh_exp,
    };

    let encoding_key = EncodingKey::from_secret(secret.as_ref());

    let access_token = encode(&Header::default(), &access_claims, &encoding_key)
        .map_err(|e| format!("Failed to create token: {}", e))?;

    let refresh_token = encode(&Header::default(), &refresh_claims, &encoding_key)
        .map_err(|e| format!("Failed to create refresh token: {}", e))?;

    Ok((access_token, refresh_token))
}

/// Verify JWT token
pub fn verify_token(token: &str, secret: &str) -> Result<JwtClaims, String> {
    let decoding_key = DecodingKey::from_secret(secret.as_ref());
    let validation = Validation::default();

    decode::<JwtClaims>(token, &decoding_key, &validation)
        .map(|data| data.claims)
        .map_err(|e| format!("Failed to verify token: {}", e))
}

/// Hash password using bcrypt
pub fn hash_password(password: &str) -> Result<String, String> {
    bcrypt::hash(password, 12)
        .map_err(|e| format!("Failed to hash password: {}", e))
}

/// Verify password
pub fn verify_password(password: &str, hash: &str) -> Result<bool, String> {
    bcrypt::verify(password, hash)
        .map_err(|e| format!("Failed to verify password: {}", e))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_password_hashing() {
        let password = "test_password_123";
        let hash = hash_password(password).expect("Failed to hash");
        assert!(verify_password(password, &hash).expect("Failed to verify"));
    }

    #[test]
    fn test_token_creation() {
        let user_id = Uuid::new_v4();
        let email = "test@example.com";
        let secret = "test_secret_key_very_long_and_secure";

        let (access, refresh) = create_token(&user_id, email, secret)
            .expect("Failed to create tokens");

        let claims = verify_token(&access, secret).expect("Failed to verify token");
        assert_eq!(claims.sub, user_id.to_string());
        assert_eq!(claims.email, email);
    }
}
