from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)
app = FastAPI(title='CineFlow AI - world uuilder')

@app.get('/health')
async def health():
    return {'status': 'healthy', 'service': 'world-builder'}

@app.get('/ready')
async def ready():
    return {'ready': True}
