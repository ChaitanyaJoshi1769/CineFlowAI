from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)
app = FastAPI(title='CineFlow AI - streaming')

@app.get('/health')
async def health():
    return {'status': 'healthy', 'service': 'streaming'}

@app.get('/ready')
async def ready():
    return {'ready': True}
