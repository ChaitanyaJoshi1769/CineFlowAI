from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)
app = FastAPI(title='CineFlow AI - video generation')

@app.get('/health')
async def health():
    return {'status': 'healthy', 'service': 'video-generation'}

@app.get('/ready')
async def ready():
    return {'ready': True}
