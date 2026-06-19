# CineFlow AI API Documentation

## Overview

CineFlow AI provides three primary API interfaces:
- **REST** - Traditional HTTP REST API
- **GraphQL** - Modern query language API
- **WebSocket** - Real-time streaming and events

## API Gateway

All requests route through the API Gateway at `https://api.cineflow.ai`

### Authentication

All endpoints require authentication except:
- `POST /auth/login`
- `POST /auth/register`
- `GET /health`
- `GET /status`

#### Bearer Token

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://api.cineflow.ai/api/v1/experiences
```

#### API Key

```bash
curl -H "X-API-Key: YOUR_API_KEY" \
  https://api.cineflow.ai/api/v1/experiences
```

### Response Format

All responses follow this format:

```json
{
  "success": true,
  "data": {
    // Response data
  },
  "errors": null,
  "timestamp": "2024-01-15T10:30:00Z",
  "request_id": "req_123abc"
}
```

Error response:

```json
{
  "success": false,
  "data": null,
  "errors": [
    {
      "code": "INVALID_REQUEST",
      "message": "Field 'title' is required",
      "field": "title"
    }
  ],
  "timestamp": "2024-01-15T10:30:00Z",
  "request_id": "req_123abc"
}
```

## REST API

### Base URL

- **Development:** `http://localhost:8000/api/v1`
- **Staging:** `https://staging-api.cineflow.ai/api/v1`
- **Production:** `https://api.cineflow.ai/api/v1`

### Authentication Endpoints

#### Login

```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "device_name": "My Device"
}

Response: 200 OK
{
  "success": true,
  "data": {
    "user": {
      "id": "usr_abc123",
      "email": "user@example.com",
      "username": "username",
      "first_name": "John",
      "last_name": "Doe",
      "avatar_url": "https://...",
      "status": "active"
    },
    "token": {
      "access_token": "eyJ...",
      "refresh_token": "eyJ...",
      "token_type": "Bearer",
      "expires_in": 86400
    }
  }
}
```

#### Register

```http
POST /auth/register
Content-Type: application/json

{
  "email": "newuser@example.com",
  "password": "password123",
  "first_name": "Jane",
  "last_name": "Smith",
  "username": "janesmith"
}

Response: 201 Created
{
  "success": true,
  "data": {
    "user": { /* user object */ },
    "verification_token": "evt_xyz789"
  }
}
```

#### Refresh Token

```http
POST /auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJ..."
}

Response: 200 OK
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "token_type": "Bearer",
    "expires_in": 86400
  }
}
```

### Experience Endpoints

#### List Experiences

```http
GET /experiences?page=1&page_size=10&sort_by=created_at&sort_order=desc

Response: 200 OK
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "exp_abc123",
        "project_id": "prj_xyz789",
        "title": "My Interactive Movie",
        "description": "An AI-generated interactive experience",
        "genre": "sci-fi",
        "status": "published",
        "runtime_minutes": 45,
        "version": 3,
        "created_at": "2024-01-10T08:00:00Z",
        "updated_at": "2024-01-15T10:30:00Z",
        "published_at": "2024-01-14T14:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "page_size": 10,
      "total_items": 45,
      "total_pages": 5,
      "has_next": true,
      "has_previous": false
    }
  }
}
```

#### Get Experience

```http
GET /experiences/{experience_id}

Response: 200 OK
{
  "success": true,
  "data": {
    "id": "exp_abc123",
    "project_id": "prj_xyz789",
    "title": "My Interactive Movie",
    "description": "An AI-generated interactive experience",
    "genre": "sci-fi",
    "target_audience": "18+",
    "runtime_minutes": 45,
    "status": "published",
    "version": 3,
    "created_at": "2024-01-10T08:00:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "published_at": "2024-01-14T14:00:00Z",
    "world_state": { /* world state object */ },
    "characters": [ /* character objects */ ],
    "scenes": [ /* scene objects */ ]
  }
}
```

#### Create Experience

```http
POST /experiences
Content-Type: application/json
Authorization: Bearer {token}

{
  "project_id": "prj_xyz789",
  "title": "New Interactive Experience",
  "description": "Description of the experience",
  "genre": "drama",
  "target_audience": "adult"
}

Response: 201 Created
{
  "success": true,
  "data": {
    "id": "exp_abc123",
    "project_id": "prj_xyz789",
    "title": "New Interactive Experience",
    // ... other fields
  }
}
```

#### Update Experience

```http
PUT /experiences/{experience_id}
Content-Type: application/json
Authorization: Bearer {token}

{
  "title": "Updated Title",
  "description": "Updated description",
  "genre": "thriller"
}

Response: 200 OK
{
  "success": true,
  "data": { /* updated experience */ }
}
```

#### Delete Experience

```http
DELETE /experiences/{experience_id}
Authorization: Bearer {token}

Response: 204 No Content
```

### Character Endpoints

#### Get Character

```http
GET /experiences/{experience_id}/characters/{character_id}

Response: 200 OK
{
  "success": true,
  "data": {
    "id": "chr_abc123",
    "experience_id": "exp_xyz789",
    "name": "Character Name",
    "role": "protagonist",
    "personality_archetype": "hero",
    "voice_id": "voice_abc123",
    "status": "alive",
    "appearance": { /* appearance details */ },
    "backstory": "Character background...",
    "goals": { /* goals */ },
    "beliefs": { /* beliefs */ },
    "relationships": [ /* relationships */ ],
    "memory": [ /* memories */ ]
  }
}
```

#### Update Character

```http
PUT /experiences/{experience_id}/characters/{character_id}
Content-Type: application/json
Authorization: Bearer {token}

{
  "name": "Updated Name",
  "personality_archetype": "mentor",
  "goals": { /* updated goals */ }
}

Response: 200 OK
{
  "success": true,
  "data": { /* updated character */ }
}
```

### Video Generation Endpoints

#### Generate Video

```http
POST /experiences/{experience_id}/generate-video
Content-Type: application/json
Authorization: Bearer {token}

{
  "scene_id": "scn_abc123",
  "engine": "runway",
  "prompt": "A dramatic scene in a futuristic city...",
  "duration_seconds": 15,
  "resolution": "1920x1080",
  "fps": 24,
  "quality_level": "high"
}

Response: 202 Accepted
{
  "success": true,
  "data": {
    "id": "vg_abc123",
    "status": "processing",
    "progress": 0,
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

#### Get Generation Status

```http
GET /video-generations/{generation_id}

Response: 200 OK
{
  "success": true,
  "data": {
    "id": "vg_abc123",
    "scene_id": "scn_abc123",
    "engine": "runway",
    "status": "completed",
    "progress": 100,
    "video_url": "https://cdn.cineflow.ai/videos/vg_abc123.mp4",
    "thumbnail_url": "https://cdn.cineflow.ai/thumbnails/vg_abc123.jpg",
    "processing_time_ms": 45000,
    "cost_usd": 2.50,
    "created_at": "2024-01-15T10:30:00Z",
    "completed_at": "2024-01-15T10:45:00Z"
  }
}
```

### Voice Generation Endpoints

#### Generate Voice

```http
POST /experiences/{experience_id}/generate-voice
Content-Type: application/json
Authorization: Bearer {token}

{
  "character_id": "chr_abc123",
  "voice_config_id": "vc_xyz789",
  "text_to_speak": "Hello, this is a test voice.",
  "emotion": "neutral",
  "emotion_intensity": 0.5
}

Response: 202 Accepted
{
  "success": true,
  "data": {
    "id": "vg_audio123",
    "status": "processing",
    "progress": 0
  }
}
```

### Interactive Endpoints

#### Record Interaction

```http
POST /experiences/{experience_id}/interactions
Content-Type: application/json
Authorization: Bearer {token}

{
  "viewer_id": "usr_abc123",
  "interactive_element_id": "ie_xyz789",
  "interaction_type": "dialogue_choice",
  "interaction_data": {
    "chosen_option": "Option A",
    "emotional_resonance": 0.8
  },
  "timestamp_seconds": 345.5
}

Response: 201 Created
{
  "success": true,
  "data": {
    "id": "interaction_123",
    "experience_id": "exp_abc123",
    "viewer_id": "usr_abc123",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### Analytics Endpoints

#### Get Engagement Metrics

```http
GET /experiences/{experience_id}/engagement/{viewer_id}

Response: 200 OK
{
  "success": true,
  "data": {
    "viewer_id": "usr_abc123",
    "experience_id": "exp_abc123",
    "total_sessions": 5,
    "total_duration_minutes": 185.5,
    "completion_rate": 0.95,
    "interaction_count": 42,
    "engagement_score": 0.87,
    "favorite_scenes": ["scn_abc123", "scn_def456"],
    "last_viewed_at": "2024-01-15T10:30:00Z"
  }
}
```

#### Get Quality Metrics

```http
GET /experiences/{experience_id}/quality-metrics?start_date=2024-01-01&end_date=2024-01-31

Response: 200 OK
{
  "success": true,
  "data": {
    "items": [
      {
        "metric_date": "2024-01-15",
        "avg_generation_time_ms": 35000,
        "avg_frame_rate": 29.8,
        "video_quality_score": 0.92,
        "audio_quality_score": 0.88,
        "narrative_coherence_score": 0.85,
        "character_consistency_score": 0.89,
        "user_satisfaction_score": 0.86
      }
    ]
  }
}
```

## GraphQL API

### Endpoint

```
https://api.cineflow.ai/graphql
```

### Example Query

```graphql
query GetExperience($id: UUID!) {
  experience(id: $id) {
    id
    title
    description
    genre
    status
    version
    characters {
      id
      name
      role
      status
      appearance
    }
    scenes(first: 10) {
      edges {
        node {
          id
          title
          sequenceNumber
          duration_seconds
          status
        }
        cursor
      }
      pageInfo {
        hasNextPage
        endCursor
        totalCount
      }
    }
    worldState {
      id
      version
      timeOfDay
      weatherState
      economyState
    }
  }
}
```

### Example Mutation

```graphql
mutation CreateExperience($input: CreateExperienceInput!) {
  createExperience(input: $input) {
    success
    experience {
      id
      title
      createdAt
    }
    errors {
      code
      message
    }
  }
}
```

### Subscriptions

Real-time updates:

```graphql
subscription OnExperienceUpdated($id: UUID!) {
  experienceUpdated(id: $id) {
    id
    title
    status
    updatedAt
  }
}
```

## WebSocket API

### Connection

```javascript
const socket = new WebSocket('wss://api.cineflow.ai/ws');

socket.addEventListener('open', (event) => {
  // Authenticate
  socket.send(JSON.stringify({
    type: 'auth',
    token: 'YOUR_TOKEN'
  }));
});

socket.addEventListener('message', (event) => {
  const message = JSON.parse(event.data);
  console.log('Received:', message);
});
```

### Message Types

#### Subscribe to Experience Updates

```javascript
socket.send(JSON.stringify({
  type: 'subscribe',
  channel: `experience:${experienceId}`,
  events: ['state_changed', 'scene_generated', 'character_updated']
}));
```

#### Subscribe to Streaming Events

```javascript
socket.send(JSON.stringify({
  type: 'subscribe',
  channel: `stream:${sessionId}`,
  events: ['frame_ready', 'quality_changed', 'error']
}));
```

#### Receive Real-time Updates

```javascript
// Example message from server
{
  "type": "event",
  "channel": "experience:exp_abc123",
  "event": "state_changed",
  "data": {
    "world_state_version": 42,
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

## Rate Limiting

### Limits

- **Authenticated Users:** 1,000 requests/minute
- **Free Plan:** 10 requests/minute
- **Pro Plan:** 100 requests/minute
- **Enterprise:** Custom limits

### Headers

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 998
X-RateLimit-Reset: 1705326600
```

### Rate Limit Exceeded

```http
HTTP 429 Too Many Requests

{
  "success": false,
  "errors": [
    {
      "code": "RATE_LIMIT_EXCEEDED",
      "message": "Rate limit exceeded. Retry after 60 seconds.",
      "retry_after": 60
    }
  ]
}
```

## Error Codes

| Code | Status | Description |
|------|--------|-------------|
| `INVALID_REQUEST` | 400 | Invalid request parameters |
| `UNAUTHORIZED` | 401 | Missing or invalid credentials |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource already exists |
| `RATE_LIMIT_EXCEEDED` | 429 | Rate limit exceeded |
| `INTERNAL_ERROR` | 500 | Internal server error |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily unavailable |

## Pagination

### Query Parameters

```
?page=1&page_size=10&sort_by=created_at&sort_order=desc
```

### Response

```json
{
  "items": [ /* array of items */ ],
  "pagination": {
    "page": 1,
    "page_size": 10,
    "total_items": 100,
    "total_pages": 10,
    "has_next": true,
    "has_previous": false
  }
}
```

## Webhooks

### Register Webhook

```http
POST /webhooks
Authorization: Bearer {token}

{
  "url": "https://your-domain.com/webhook",
  "events": ["experience.published", "video.generated", "error.occurred"],
  "active": true
}
```

### Webhook Event

```json
{
  "id": "evt_abc123",
  "type": "experience.published",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "experience_id": "exp_abc123",
    "title": "My Experience",
    "version": 3
  },
  "retry_count": 0
}
```

## SDKs

See `/sdks` for official SDKs:
- JavaScript/TypeScript
- Python
- Go
- Rust
- Java
- Swift
- Kotlin

## Support

- **Issues:** https://github.com/ChaitanyaJoshi1769/CineFlowAI/issues
- **Discord:** https://discord.gg/cineflow
- **Email:** api-support@cineflow.ai
