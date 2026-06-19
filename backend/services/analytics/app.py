from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)
app = FastAPI(title='CineFlow AI - analytics')

@app.get('/health')
async def health():
    return {'status': 'healthy', 'service': 'analytics'}

@app.get('/ready')
async def ready():
    return {'ready': True}
