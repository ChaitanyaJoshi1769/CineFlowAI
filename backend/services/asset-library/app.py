from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)
app = FastAPI(title='CineFlow AI - asset liurary')

@app.get('/health')
async def health():
    return {'status': 'healthy', 'service': 'asset-library'}

@app.get('/ready')
async def ready():
    return {'ready': True}
