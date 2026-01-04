FROM --platform=linux/amd64 pytorch/pytorch

# ==========================================
# 1. 基础环境与用户设置 (平台硬性要求)
# ==========================================
ENV PYTHONUNBUFFERED=1
RUN groupadd -r user && useradd -m --no-log-init -r -g user user
USER user
WORKDIR /opt/app

# ==========================================
# 2. 安装依赖库
# ==========================================
# scipy: 用于 model.py 中的 zoom 和 label (必须有!)
# simpleitk: 用于读取医学图像 (必须有!)
RUN python -m pip install \
    --user \
    --no-cache-dir \
    numpy \
    scipy \
    simpleitk

# ==========================================
# 3. 复制 Python 代码
# ==========================================
# ⚠️ 确保你本地目录下有这三个文件
COPY --chown=user:user trackrad_unet_v2.py /opt/app/
COPY --chown=user:user inference.py /opt/app/
COPY --chown=user:user model.py /opt/app/

# 创建资源目录
RUN mkdir -p /opt/app/resources

# ==========================================
# 4. 【核心】下载模型 + 强制检查大小
# ==========================================
# 逻辑：下载 -> 检查是否大于 100MB -> 如果太小则报错退出(构建失败)
RUN python -c "import urllib.request, os, sys; \
    url = 'https://huggingface.co/xiaomao99/best_model/resolve/main/best_model.pth?download=true'; \
    dest = '/opt/app/resources/best_model.pth'; \
    print(f'⬇️  Start downloading model from {url}...'); \
    try: \
        urllib.request.urlretrieve(url, dest); \
        file_size_mb = os.path.getsize(dest) / (1024 * 1024); \
        print(f'✅ Download finished. File size: {file_size_mb:.2f} MB'); \
        if file_size_mb < 100: \
            print('❌ CRITICAL ERROR: File is too small (<100MB)!'); \
            print('   Likely causes:'); \
            print('   1. Hugging Face repo is PRIVATE (Must be Public).'); \
            print('   2. URL is wrong.'); \
            sys.exit(1); \
        else: \
            print('🎉 Model integrity check passed!'); \
    except Exception as e: \
        print(f'❌ Download failed: {e}'); \
        sys.exit(1);"

# ==========================================
# 5. 设置入口
# ==========================================
ENTRYPOINT ["python", "inference.py"]