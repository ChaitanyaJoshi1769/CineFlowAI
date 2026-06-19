from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)
app = FastAPI(title='CineFlow AI - admin')

@app.get('/health')
async def health():
    return {'status': 'healthy', 'service': 'admin'}

@app.get('/ready')
async def ready():
    return {'ready': True}
