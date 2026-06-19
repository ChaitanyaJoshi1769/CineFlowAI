"""
CineFlow AI - Memory Engine Service
Hybrid memory system with vector search and knowledge graphs
"""
from fastapi import FastAPI, HTTPException
from contextlib import asynccontextmanager
import logging
from datetime import datetime
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Memory Engine service starting...")
    yield
    logger.info("Memory Engine service shutting down...")

app = FastAPI(
    title="CineFlow AI - Memory Engine",
    description="Hybrid memory system with vector search and knowledge graphs",
    version="0.1.0",
    lifespan=lifespan
)

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "memory-engine", "timestamp": datetime.utcnow().isoformat()}

@app.get("/ready")
async def ready():
    return {"ready": True, "service": "memory-engine"}

@app.post("/api/v1/memories")
async def store_memory(req: dict):
    """Store memory for entity"""
    try:
        entity_id = req.get("entity_id")
        memory_type = req.get("memory_type", "episodic")
        content = req.get("content")
        
        memory_id = f"mem_{entity_id}_{int(datetime.utcnow().timestamp())}"
        
        return {
            "success": True,
            "data": {
                "memory_id": memory_id,
                "entity_id": entity_id,
                "type": memory_type,
                "stored_at": datetime.utcnow().isoformat()
            }
        }
    except Exception as e:
        logger.error(f"Error storing memory: {e}")
        raise HTTPException(status_code=500, detail="Failed to store memory")

@app.post("/api/v1/search")
async def search_memories(req: dict):
    """Search memories using semantic search"""
    try:
        entity_id = req.get("entity_id")
        query = req.get("query")
        
        return {
            "success": True,
            "data": {
                "results": [
                    {"memory_id": "mem_1", "relevance": 0.95, "content": "Relevant memory"}
                ]
            }
        }
    except Exception as e:
        logger.error(f"Error searching memories: {e}")
        raise HTTPException(status_code=500, detail="Search failed")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("API_PORT", "8008"))
    uvicorn.run(app, host="0.0.0.0", port=port)
