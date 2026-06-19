from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)
app = FastAPI(title='CineFlow AI - voice engine')

@app.get('/health')
async def health():
    return {'status': 'healthy', 'service': 'voice-engine'}

@app.get('/ready')
async def ready():
    return {'ready': True}
