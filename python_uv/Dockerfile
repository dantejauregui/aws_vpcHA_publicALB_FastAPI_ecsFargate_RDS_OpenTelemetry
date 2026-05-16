# Use an official Python base image
FROM python:3.12-slim-trixie
COPY --from=ghcr.io/astral-sh/uv:0.10.2 /uv /uvx /bin/

# Set the working directory
WORKDIR /app

# Copy the UV dependencies list
COPY pyproject.toml uv.lock /app

# Install Python packages with UV
RUN uv sync --no-dev --locked --no-editable --no-install-project

# Copy your FastAPI app
COPY main.py /app

# application runtime environment ".env" takes precedence (over system Python using $PATH)
ENV PATH="/app/.venv/bin:$PATH"

# Run the app with Uvicorn defining PID1 (Container lifecycle == PID1 lifecycle):
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]