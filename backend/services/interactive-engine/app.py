from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)
app = FastAPI(title='CineFlow AI - interactive engine')

@app.get('/health')
async def health():
    return {'status': 'healthy', 'service': 'interactive-engine'}

@app.get('/ready')
async def ready():
    return {'ready': True}
