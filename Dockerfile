FROM --platform=linux/amd64 pytorch/pytorch

# 1. 基础环境设置
ENV PYTHONUNBUFFERED=1
RUN groupadd -r user && useradd -m --no-log-init -r -g user user
USER user
WORKDIR /opt/app

# 2. 安装所有依赖 (包含 scipy, simpleitk)
# 这些库是 model.py 运行的刚需
RUN python -m pip install \
    --user \
    --no-cache-dir \
    numpy \
    scipy \
    simpleitk

# 3. 复制 Python 代码
# 必须包含 trackrad_unet_v2.py，否则 model.py 会报错
COPY --chown=user:user trackrad_unet_v2.py /opt/app/
COPY --chown=user:user inference.py /opt/app/
COPY --chown=user:user model.py /opt/app/

# 4. 创建资源文件夹
RUN mkdir -p /opt/app/resources

# 5. 【核心】从 Hugging Face 下载模型 (已替换为你的链接)
# 这一步会在构建时自动把 377MB 的权重下到镜像里
RUN python -c "import urllib.request; \
    url = 'https://huggingface.co/xiaomao99/best_model/resolve/main/best_model.pth?download=true'; \
    print(f'Downloading model from {url}...'); \
    urllib.request.urlretrieve(url, '/opt/app/resources/best_model.pth'); \
    print('Download complete!')"

# 6. 设置入口
ENTRYPOINT ["python", "inference.py"]