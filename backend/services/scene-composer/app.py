from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)
app = FastAPI(title='CineFlow AI - scene composer')

@app.get('/health')
async def health():
    return {'status': 'healthy', 'service': 'scene-composer'}

@app.get('/ready')
async def ready():
    return {'ready': True}
