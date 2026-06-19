"""
CineFlow AI - Story Engine Service
Manages world state, character state, and narrative consistency
"""

from fastapi import FastAPI, HTTPException, Depends
from fastapi.responses import JSONResponse
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from contextlib import asynccontextmanager
import os
import logging
from datetime import datetime
import uuid

from models import Base, Experience, WorldState, Character, Scene, Event
from schemas import (
    ExperienceCreate, ExperienceUpdate, ExperienceResponse,
    WorldStateCreate, CharacterCreate, CharacterUpdate,
    SceneCreate, SceneUpdate
)
from database import get_db
from services.story_service import StoryService
from services.character_service import CharacterService
from services.world_service import WorldService

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
    logger.info("Story Engine service starting...")
    yield
    logger.info("Story Engine service shutting down...")

# FastAPI app
app = FastAPI(
    title="CineFlow AI - Story Engine",
    description="Manages narrative state, world state, and character interactions",
    version="0.1.0",
    lifespan=lifespan
)

# Initialize services
story_service = StoryService(SessionLocal)
character_service = CharacterService(SessionLocal)
world_service = WorldService(SessionLocal)

# ============================================================================
# Health & Status Endpoints
# ============================================================================

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "story-engine",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/ready")
async def ready():
    """Readiness check endpoint"""
    try:
        db = SessionLocal()
        db.execute("SELECT 1")
        db.close()
        return {"ready": True, "service": "story-engine"}
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        raise HTTPException(status_code=503, detail="Service not ready")

# ============================================================================
# Experience Endpoints
# ============================================================================

@app.post("/api/v1/experiences", response_model=ExperienceResponse)
async def create_experience(
    req: ExperienceCreate,
    db: Session = Depends(get_db)
):
    """Create a new experience"""
    try:
        experience = story_service.create_experience(db, req)
        return ExperienceResponse.from_orm(experience)
    except Exception as e:
        logger.error(f"Error creating experience: {e}")
        raise HTTPException(status_code=400, detail="Failed to create experience")

@app.get("/api/v1/experiences/{experience_id}", response_model=ExperienceResponse)
async def get_experience(
    experience_id: str,
    db: Session = Depends(get_db)
):
    """Get experience by ID"""
    try:
        experience = story_service.get_experience(db, experience_id)
        if not experience:
            raise HTTPException(status_code=404, detail="Experience not found")
        return ExperienceResponse.from_orm(experience)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting experience: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.put("/api/v1/experiences/{experience_id}", response_model=ExperienceResponse)
async def update_experience(
    experience_id: str,
    req: ExperienceUpdate,
    db: Session = Depends(get_db)
):
    """Update experience"""
    try:
        experience = story_service.update_experience(db, experience_id, req)
        return ExperienceResponse.from_orm(experience)
    except Exception as e:
        logger.error(f"Error updating experience: {e}")
        raise HTTPException(status_code=400, detail="Failed to update experience")

@app.delete("/api/v1/experiences/{experience_id}")
async def delete_experience(
    experience_id: str,
    db: Session = Depends(get_db)
):
    """Delete experience"""
    try:
        story_service.delete_experience(db, experience_id)
        return {"success": True}
    except Exception as e:
        logger.error(f"Error deleting experience: {e}")
        raise HTTPException(status_code=400, detail="Failed to delete experience")

# ============================================================================
# World State Endpoints
# ============================================================================

@app.post("/api/v1/experiences/{experience_id}/world-state")
async def create_world_state(
    experience_id: str,
    req: WorldStateCreate,
    db: Session = Depends(get_db)
):
    """Create world state for experience"""
    try:
        world_state = world_service.create_world_state(db, experience_id, req)
        return {
            "success": True,
            "data": {
                "id": str(world_state.id),
                "experience_id": str(world_state.experience_id),
                "version": world_state.version,
                "facts": world_state.facts,
                "lore": world_state.lore
            }
        }
    except Exception as e:
        logger.error(f"Error creating world state: {e}")
        raise HTTPException(status_code=400, detail="Failed to create world state")

@app.get("/api/v1/experiences/{experience_id}/world-state")
async def get_world_state(
    experience_id: str,
    db: Session = Depends(get_db)
):
    """Get current world state"""
    try:
        world_state = world_service.get_current_world_state(db, experience_id)
        if not world_state:
            raise HTTPException(status_code=404, detail="World state not found")
        return {
            "success": True,
            "data": {
                "id": str(world_state.id),
                "experience_id": str(world_state.experience_id),
                "version": world_state.version,
                "facts": world_state.facts,
                "lore": world_state.lore
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting world state: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

# ============================================================================
# Character Endpoints
# ============================================================================

@app.post("/api/v1/experiences/{experience_id}/characters")
async def create_character(
    experience_id: str,
    req: CharacterCreate,
    db: Session = Depends(get_db)
):
    """Create character in experience"""
    try:
        character = character_service.create_character(db, experience_id, req)
        return {
            "success": True,
            "data": {
                "id": str(character.id),
                "name": character.name,
                "role": character.role,
                "personality_archetype": character.personality_archetype,
                "status": character.status
            }
        }
    except Exception as e:
        logger.error(f"Error creating character: {e}")
        raise HTTPException(status_code=400, detail="Failed to create character")

@app.get("/api/v1/experiences/{experience_id}/characters/{character_id}")
async def get_character(
    experience_id: str,
    character_id: str,
    db: Session = Depends(get_db)
):
    """Get character details"""
    try:
        character = character_service.get_character(db, character_id)
        if not character:
            raise HTTPException(status_code=404, detail="Character not found")
        return {
            "success": True,
            "data": {
                "id": str(character.id),
                "name": character.name,
                "role": character.role,
                "personality_archetype": character.personality_archetype,
                "status": character.status,
                "goals": character.goals,
                "beliefs": character.beliefs
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting character: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.put("/api/v1/experiences/{experience_id}/characters/{character_id}")
async def update_character(
    experience_id: str,
    character_id: str,
    req: CharacterUpdate,
    db: Session = Depends(get_db)
):
    """Update character"""
    try:
        character = character_service.update_character(db, character_id, req)
        return {
            "success": True,
            "data": {
                "id": str(character.id),
                "name": character.name,
                "status": character.status
            }
        }
    except Exception as e:
        logger.error(f"Error updating character: {e}")
        raise HTTPException(status_code=400, detail="Failed to update character")

# ============================================================================
# Scene Endpoints
# ============================================================================

@app.post("/api/v1/experiences/{experience_id}/scenes")
async def create_scene(
    experience_id: str,
    req: SceneCreate,
    db: Session = Depends(get_db)
):
    """Create scene in experience"""
    try:
        scene = story_service.create_scene(db, experience_id, req)
        return {
            "success": True,
            "data": {
                "id": str(scene.id),
                "title": scene.title,
                "sequence_number": scene.sequence_number,
                "status": scene.status
            }
        }
    except Exception as e:
        logger.error(f"Error creating scene: {e}")
        raise HTTPException(status_code=400, detail="Failed to create scene")

@app.get("/api/v1/experiences/{experience_id}/scenes/{scene_id}")
async def get_scene(
    experience_id: str,
    scene_id: str,
    db: Session = Depends(get_db)
):
    """Get scene details"""
    try:
        scene = story_service.get_scene(db, scene_id)
        if not scene:
            raise HTTPException(status_code=404, detail="Scene not found")
        return {
            "success": True,
            "data": {
                "id": str(scene.id),
                "title": scene.title,
                "description": scene.description,
                "location": scene.location,
                "status": scene.status
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting scene: {e}")
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

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={"success": False, "error": "Internal server error"}
    )

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("API_PORT", "8002"))
    uvicorn.run(app, host="0.0.0.0", port=port)
