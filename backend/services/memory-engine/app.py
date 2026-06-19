from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)
app = FastAPI(title='CineFlow AI - memory engine')

@app.get('/health')
async def health():
    return {'status': 'healthy', 'service': 'memory-engine'}

@app.get('/ready')
async def ready():
    return {'ready': True}
