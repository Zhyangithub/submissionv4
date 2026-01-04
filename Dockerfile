FROM --platform=linux/amd64 pytorch/pytorch

ENV PYTHONUNBUFFERED=1

RUN groupadd -r user && useradd -m --no-log-init -r -g user user
USER user

WORKDIR /opt/app

# 安装必要的库
RUN python -m pip install \
    --user \
    --no-cache-dir \
    numpy \
    scipy \
    simpleitk

# 1. 复制训练代码 (因为 model.py 引用了它)
COPY --chown=user:user trackrad_unet_v2.py /opt/app/

# 2. 复制推理代码
COPY --chown=user:user inference.py /opt/app/
COPY --chown=user:user model.py /opt/app/

# 3. 复制权重资源
COPY --chown=user:user resources /opt/app/resources

ENTRYPOINT ["python", "inference.py"]