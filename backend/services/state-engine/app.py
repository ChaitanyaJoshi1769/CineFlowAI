"""
CineFlow AI - State Engine Service
Event sourcing, state snapshots, and temporal timeline management
"""

from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
from fastapi.responses import JSONResponse
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from contextlib import asynccontextmanager
import os
import logging
from datetime import datetime
import json

from models import Base, Event, EventSnapshot, StateTimeline
from schemas import (
    EventCreate, EventResponse, SnapshotCreate,
    TimelineQuery, StateQuery
)
from database import get_db
from services.event_store import EventStore
from services.snapshot_service import SnapshotService
from services.timeline_service import TimelineService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database setup
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/cineflow")
engine = create_engine(DATABASE_URL, echo=False)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create tables
Base.metadata.create_all(bind=engine)

# Lifespan events
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events"""
    logger.info("State Engine service starting...")
    yield
    logger.info("State Engine service shutting down...")

# FastAPI app
app = FastAPI(
    title="CineFlow AI - State Engine",
    description="Manages event sourcing, state snapshots, and temporal timelines",
    version="0.1.0",
    lifespan=lifespan
)

# Initialize services
event_store = EventStore(SessionLocal)
snapshot_service = SnapshotService(SessionLocal)
timeline_service = TimelineService(SessionLocal)

# ============================================================================
# Health & Status Endpoints
# ============================================================================

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "state-engine",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/ready")
async def ready():
    """Readiness check endpoint"""
    try:
        db = SessionLocal()
        db.execute("SELECT 1")
        db.close()
        return {"ready": True, "service": "state-engine"}
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        raise HTTPException(status_code=503, detail="Service not ready")

# ============================================================================
# Event Sourcing Endpoints
# ============================================================================

@app.post("/api/v1/experiences/{experience_id}/events", response_model=EventResponse)
async def record_event(
    experience_id: str,
    req: EventCreate,
    db: Session = Depends(get_db)
):
    """Record event for experience (event sourcing)"""
    try:
        event = event_store.append_event(db, experience_id, req)
        return EventResponse.from_orm(event)
    except Exception as e:
        logger.error(f"Error recording event: {e}")
        raise HTTPException(status_code=400, detail="Failed to record event")

@app.get("/api/v1/experiences/{experience_id}/events")
async def list_events(
    experience_id: str,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """List events for experience"""
    try:
        events = event_store.get_events(db, experience_id, skip, limit)
        return {
            "success": True,
            "data": {
                "items": [
                    {
                        "id": str(event.id),
                        "event_type": event.event_type,
                        "actor_id": event.actor_id,
                        "action": event.action,
                        "sequence_number": event.sequence_number,
                        "timestamp": event.timestamp.isoformat()
                    }
                    for event in events
                ]
            }
        }
    except Exception as e:
        logger.error(f"Error listing events: {e}")
        raise HTTPException(status_code=500, detail="Failed to list events")

@app.get("/api/v1/experiences/{experience_id}/events/{event_id}")
async def get_event(
    experience_id: str,
    event_id: str,
    db: Session = Depends(get_db)
):
    """Get specific event"""
    try:
        event = event_store.get_event(db, event_id)
        if not event:
            raise HTTPException(status_code=404, detail="Event not found")
        return {
            "success": True,
            "data": {
                "id": str(event.id),
                "experience_id": str(event.experience_id),
                "event_type": event.event_type,
                "actor_id": event.actor_id,
                "action": event.action,
                "payload": event.payload,
                "sequence_number": event.sequence_number,
                "timestamp": event.timestamp.isoformat()
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting event: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

# ============================================================================
# State Snapshots Endpoints
# ============================================================================

@app.post("/api/v1/experiences/{experience_id}/snapshots")
async def create_snapshot(
    experience_id: str,
    req: SnapshotCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Create state snapshot"""
    try:
        snapshot = snapshot_service.create_snapshot(db, experience_id, req)
        return {
            "success": True,
            "data": {
                "id": str(snapshot.id),
                "experience_id": str(snapshot.experience_id),
                "entity_id": snapshot.entity_id,
                "entity_type": snapshot.entity_type,
                "snapshot_version": snapshot.snapshot_version,
                "created_at": snapshot.created_at.isoformat()
            }
        }
    except Exception as e:
        logger.error(f"Error creating snapshot: {e}")
        raise HTTPException(status_code=400, detail="Failed to create snapshot")

@app.get("/api/v1/experiences/{experience_id}/snapshots/{entity_id}")
async def get_latest_snapshot(
    experience_id: str,
    entity_id: str,
    db: Session = Depends(get_db)
):
    """Get latest snapshot for entity"""
    try:
        snapshot = snapshot_service.get_latest_snapshot(db, entity_id)
        if not snapshot:
            return {
                "success": True,
                "data": None
            }
        return {
            "success": True,
            "data": {
                "id": str(snapshot.id),
                "entity_id": snapshot.entity_id,
                "snapshot_version": snapshot.snapshot_version,
                "state": snapshot.state,
                "created_at": snapshot.created_at.isoformat()
            }
        }
    except Exception as e:
        logger.error(f"Error getting snapshot: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

# ============================================================================
# Timeline & Replay Endpoints
# ============================================================================

@app.post("/api/v1/experiences/{experience_id}/replay")
async def replay_to_point(
    experience_id: str,
    req: TimelineQuery,
    db: Session = Depends(get_db)
):
    """Replay state to specific point in time"""
    try:
        state = timeline_service.reconstruct_state(db, experience_id, req)
        return {
            "success": True,
            "data": {
                "state": state,
                "reconstructed_at": datetime.utcnow().isoformat()
            }
        }
    except Exception as e:
        logger.error(f"Error replaying state: {e}")
        raise HTTPException(status_code=400, detail="Failed to replay state")

@app.get("/api/v1/experiences/{experience_id}/state-at/{timestamp}")
async def get_state_at_time(
    experience_id: str,
    timestamp: str,
    db: Session = Depends(get_db)
):
    """Get state at specific timestamp (time travel)"""
    try:
        state = timeline_service.get_state_at_time(db, experience_id, timestamp)
        return {
            "success": True,
            "data": {
                "state": state,
                "timestamp": timestamp
            }
        }
    except Exception as e:
        logger.error(f"Error getting state at time: {e}")
        raise HTTPException(status_code=400, detail="Failed to get state")

@app.post("/api/v1/experiences/{experience_id}/diff")
async def get_state_diff(
    experience_id: str,
    req: StateQuery,
    db: Session = Depends(get_db)
):
    """Get diff between two states"""
    try:
        diff = timeline_service.get_state_diff(db, req.from_timestamp, req.to_timestamp)
        return {
            "success": True,
            "data": {"diff": diff}
        }
    except Exception as e:
        logger.error(f"Error getting diff: {e}")
        raise HTTPException(status_code=400, detail="Failed to get diff")

# ============================================================================
# Version History Endpoints
# ============================================================================

@app.get("/api/v1/experiences/{experience_id}/history")
async def get_version_history(
    experience_id: str,
    entity_id: str,
    db: Session = Depends(get_db)
):
    """Get version history for entity"""
    try:
        history = event_store.get_entity_history(db, entity_id)
        return {
            "success": True,
            "data": {
                "items": [
                    {
                        "version": item.get("version"),
                        "timestamp": item.get("timestamp"),
                        "actor": item.get("actor")
                    }
                    for item in history
                ]
            }
        }
    except Exception as e:
        logger.error(f"Error getting history: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

# ============================================================================
# Error Handlers
# ============================================================================

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={"success": False, "error": exc.detail}
    )

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("API_PORT", "8003"))
    uvicorn.run(app, host="0.0.0.0", port=port)
