"""Performance benchmarks for CineFlow API"""
import asyncio
import time
from httpx import AsyncClient

async def benchmark_endpoint(url: str, method: str = "GET", payload: dict = None, iterations: int = 1000):
    """Benchmark an endpoint"""
    client = AsyncClient(base_url="http://localhost:8000")
    
    times = []
    for _ in range(iterations):
        start = time.time()
        if method == "GET":
            await client.get(url)
        elif method == "POST":
            await client.post(url, json=payload)
        times.append(time.time() - start)
    
    avg = sum(times) / len(times)
    p99 = sorted(times)[int(len(times) * 0.99)]
    
    print(f"Endpoint: {url}")
    print(f"  Avg latency: {avg*1000:.2f}ms")
    print(f"  p99 latency: {p99*1000:.2f}ms")
    print(f"  Throughput: {iterations/sum(times):.0f} req/s")

async def main():
    await benchmark_endpoint("/health")
    await benchmark_endpoint("/api/v1/experiences", method="POST", payload={"title": "Test"})

if __name__ == "__main__":
    asyncio.run(main())
