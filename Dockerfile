# =========================
# Base image
# =========================
FROM python:3.10-slim

# =========================
# System dependencies
# =========================
RUN apt-get update && apt-get install -y \
    git \
    git-lfs \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# =========================
# Set workdir
# =========================
WORKDIR /app

# =========================
# Copy repository content
# （必须在 git lfs pull 之前）
# =========================
COPY . /app

# =========================
# Initialize and pull Git LFS files
# ★ 这是你之前缺失的致命步骤 ★
# =========================
RUN git lfs install && git lfs pull

# =========================
# Python dependencies
# =========================
RUN pip install --no-cache-dir -r requirements.txt

# =========================
# Safety check (强烈建议保留)
# 如果权重没拉下来，这里直接失败
# =========================
RUN python - << 'EOF'
import os
p = "resources/best_model.pth"
assert os.path.exists(p), "❌ best_model.pth not found"
size = os.path.getsize(p)
print("✔ best_model.pth size:", size)
assert size > 100_000_000, "❌ best_model.pth is too small (LFS not pulled)"
EOF

# =========================
# Default command (TrackRAD)
# =========================
CMD ["python", "inference.py"]
