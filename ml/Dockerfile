FROM python:3.11-slim

WORKDIR /app

# This image is heavier than the backend's -- expect it to grow as GBM/GNN
# libraries (lightgbm, torch-geometric, etc.) get added ahead of Phase 2/3.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8500

CMD ["uvicorn", "src.serve:app", "--host", "0.0.0.0", "--port", "8500", "--reload"]
