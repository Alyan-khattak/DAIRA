FROM python:3.11-slim

WORKDIR /app

# System deps kept minimal on purpose -- this image should stay light since
# it's the API layer, not where heavy ML libraries live.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
