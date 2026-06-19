from setuptools import setup, find_packages

setup(
    name="cineflow-sdk",
    version="0.1.0",
    description="CineFlow AI - Python SDK",
    author="CineFlow AI",
    packages=find_packages(),
    install_requires=[
        "requests>=2.31.0",
        "pydantic>=2.0.0",
    ],
    python_requires=">=3.8",
)
