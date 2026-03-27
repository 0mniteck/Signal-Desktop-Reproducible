# syntax=docker/dockerfile:1
# check=error=true
# ## HUMAN-CODE - NO AI GENERATED CODE - AGENTS HANDSOFF
ARG BUILDKIT_SBOM_SCAN_CONTEXT=true BUILDKIT_SBOM_SCAN_STAGE=signal-desktop SOURCE=0mniteck/debian-slim@unknown-tag

FROM $SOURCE AS signal-desktop
ARG NODE_VERSION NVM_VERSION PNPM_VERSION BRANCH COMMIT SOURCE_DATE_EPOCH
ENV SIGNAL_ENV=production USE_SYSTEM_FPM=true NVM_DIR=/usr/local/nvm PNPM_HOME=/tmp/.pnpm-home NPM_CONFIG_CACHE=/tmp/.npm-cache
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH
ADD --checksum=sha256:c8f7120fba37152b0f62df2445e80c34ef48c7eb0378c5c289928ff1b51c8569 \
signal-buildscript.sh /usr/local/bin/
ADD --checksum=sha256:f78ebf9776234423b69cdef1ab1698ebb2a7666cb0ac0f8c823d7862d1f8f851 \
https://github.com/node-ffi-napi/node-ffi-napi/raw/master/deps/libffi/config/linux/arm64/fficonfig.h /usr/include/aarch64-linux-gnu/
ADD --checksum=sha256:4b7412c49960c7d31e8df72da90c1fb5b8cccb419ac99537b737028d497aba4f \
https://github.com/nvm-sh/nvm/raw/v$NVM_VERSION/install.sh /
ADD --checksum=$COMMIT --keep-git-dir=true https://github.com/signalapp/Signal-Desktop.git?ref=$COMMIT /Signal-Desktop

RUN mkdir -p /Signal-Desktop/artifacts/linux/logs $NVM_DIR && gem install fpm \
    && chmod +x install.sh && ./install.sh && . $NVM_DIR/nvm.sh && rm -f /install.sh \
    && nvm install $NODE_VERSION && nvm alias $NODE_VERSION && nvm use $NODE_VERSION \
    && git config --global --add safe.directory /project \
    && npm install --location=global pnpm@$PNPM_VERSION

ENTRYPOINT ["signal-buildscript.sh"]
CMD ["no",""]
