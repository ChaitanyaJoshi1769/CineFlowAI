from fastapi import FastAPI, HTTPException
from contextlib import asynccontextmanager
import logging
from datetime import datetime
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("analytics service starting...")
    yield
    logger.info("analytics service shutting down...")

app = FastAPI(
    title="CineFlow AI - analytics",
    version="0.1.0",
    lifespan=lifespan
)

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": "analytics",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/ready")
async def ready():
    return {"ready": True, "service": "analytics"}

@app.post("/api/v1/test")
async def test_endpoint(req: dict):
    try:
        return {"success": True, "data": {"service": "analytics", "status": "operational"}}
    except Exception as e:
        logger.error(f"Error: {e}")
        raise HTTPException(status_code=500, detail="Service error")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("API_PORT", "8010"))
    uvicorn.run(app, host="0.0.0.0", port=port)
