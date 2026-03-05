# check=error=true
ARG SOURCE=0mniteck/debian-slim
FROM $SOURCE
ARG NODE_VERSION NVM_VERSION PNPM_VERSION BRANCH COMMIT SOURCE_DATE_EPOCH
ENV CI=true SIGNAL_ENV=production USE_SYSTEM_FPM=true NVM_DIR="/usr/local/nvm" NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH

COPY --link signal-buildscript.sh /usr/local/bin/
ADD --link https://github.com/nvm-sh/nvm/raw/v$NVM_VERSION/install.sh /
ADD --link https://github.com/node-ffi-napi/node-ffi-napi/raw/master/deps/libffi/config/linux/arm64/fficonfig.h /
ADD --link --keep-git-dir=true https://github.com/signalapp/Signal-Desktop.git?branch=$BRANCH.x&checksum=$COMMIT /Signal-Desktop

RUN echo "a8e082d8d1a9b61a09e5d3e1902d2930e5b1b84a86f9777c7d2eb50ea204c0141f6a97c54a860bc3282e7b000f1c669c755f5e0db7bd6d492072744c302c0a21  install.sh" | sha512sum --status -c - && echo "install.sh Checksum Matched!" || exit 1
RUN echo "56c9800d0388dd20a85ad917a75a0dc96aa0de95db560e586b540e657a7a10ec8ef9759f1d09d7cb2f0861c9b88650246a9ace97708a20d8757bcd0c559333a7  fficonfig.h" | sha512sum --status -c - && echo "fficonfig.h Checksum Matched!" || exit 1
RUN mkdir -p $NVM_DIR && gem install fpm && chmod +x install.sh && ./install.sh && . $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm alias $NODE_VERSION && nvm use $NODE_VERSION
RUN mkdir -p /Signal-Desktop/artifacts/linux/logs
RUN mv fficonfig.h /usr/include/aarch64-linux-gnu/fficonfig.h
RUN git config --global --add safe.directory /project
RUN npm install --location=global pnpm@$PNPM_VERSION

ENTRYPOINT ["signal-buildscript.sh"]
CMD ["no",""]
