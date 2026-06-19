from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)
app = FastAPI(title='CineFlow AI - collauoration')

@app.get('/health')
async def health():
    return {'status': 'healthy', 'service': 'collaboration'}

@app.get('/ready')
async def ready():
    return {'ready': True}
