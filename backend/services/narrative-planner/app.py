"""
CineFlow AI - Narrative Planner Service
LLM-powered narrative planning and dynamic story generation
"""

from fastapi import FastAPI, HTTPException, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.orm import sessionmaker, Session
from contextlib import asynccontextmanager
import os
import logging
from datetime import datetime
import json

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/cineflow")

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Narrative Planner service starting...")
    yield
    logger.info("Narrative Planner service shutting down...")

app = FastAPI(
    title="CineFlow AI - Narrative Planner",
    description="LLM-powered narrative planning and adaptive storytelling",
    version="0.1.0",
    lifespan=lifespan
)

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "narrative-planner",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/ready")
async def ready():
    return {"ready": True, "service": "narrative-planner"}

@app.post("/api/v1/experiences/{experience_id}/plan")
async def generate_narrative_plan(experience_id: str, req: dict):
    """Generate narrative plan using LLM"""
    try:
        # This would integrate with OpenAI/Claude
        plan = {
            "experience_id": experience_id,
            "story_arcs": [],
            "character_arcs": [],
            "key_scenes": [],
            "narrative_branches": []
        }
        return {"success": True, "data": plan}
    except Exception as e:
        logger.error(f"Error generating plan: {e}")
        raise HTTPException(status_code=400, detail="Failed to generate plan")

@app.post("/api/v1/experiences/{experience_id}/next-scene")
async def generate_next_scene(experience_id: str, req: dict):
    """Generate next scene based on current state"""
    try:
        scene = {
            "title": "Generated Scene",
            "description": "AI-generated scene",
            "prompt": "Generate a dramatic scene",
            "characters": [],
            "environment": {}
        }
        return {"success": True, "data": scene}
    except Exception as e:
        raise HTTPException(status_code=400, detail="Failed to generate scene")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("API_PORT", "8004"))
    uvicorn.run(app, host="0.0.0.0", port=port)
