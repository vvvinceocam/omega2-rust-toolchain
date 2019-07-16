FROM rust:1.36

# Install GNU awk, required by the `feeds` scripts of the OpenWRT SDK
RUN apt-get update && \
    apt-get install -y --no-install-recommends gawk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Define compilation target an SDK version
ENV TARGET=mipsel-unknown-linux-musl \
    SDK=openwrt-sdk-18.06.4-ramips-mt76x8_gcc-7.3.0_musl.Linux-x86_64 \
    SDK_SHA256=aeb55c36c19cc9d93279d7ca80afef6c63a45e749eb0332ac3aba5f466bb8a08
# define
ENV STAGING_DIR=/opt/$SDK/staging_dir/toolchain-mipsel_24kc_gcc-7.3.0_musl \
    TARGET_USR=/opt/$SDK/staging_dir/target-mipsel_24kc_musl/usr

# Install Rust toolchain for MIPSel architecture targeting musl libc
RUN rustup target add $TARGET

# Install OpenWRT 18.06 SDK for MT7688 chip
WORKDIR /opt
ADD https://downloads.openwrt.org/releases/18.06.4/targets/ramips/mt76x8/$SDK.tar.xz .
RUN [ "$SDK_SHA256  $SDK.tar.xz" = "$(sha256sum $SDK.tar.xz)" ]
RUN tar xf $SDK.tar.xz && \
    rm $SDK.tar.xz

# Compile and install target's static openssl lib
WORKDIR /opt/$SDK
ADD ./toolchain-config .config
RUN ./scripts/feeds update -a && \
    ./scripts/feeds install openssl && \
    make package/openssl/compile
ENV OPENSSL_DIR=$STAGING_DIR/usr/ \
    OPENSSL_INCLUDE_DIR=$TARGET_USR/include/ \
    DEP_OPENSSL_INCLUDE=$TARGET_USR/include/ \
    OPENSSL_LIB_DIR=$TARGET_USR/lib/ \
    OPENSSL_STATIC=1

# Add handy access to the target's strip utility
RUN echo "#! /bin/sh\n$STAGING_DIR/bin/mipsel-openwrt-linux-strip \$@" > /usr/local/bin/strip && \
    chmod +x /usr/local/bin/strip

# Create a dedicated user
RUN useradd rust --user-group --create-home --shell /bin/bash

# Copy configuration files
ADD ./cargo-config.toml /home/rust/.cargo/config
RUN sed -ie "s#{{ target }}#${TARGET}#" /home/rust/.cargo/config && \
    sed -ie "s#{{ staging_dir }}#${STAGING_DIR}#" /home/rust/.cargo/config

VOLUME ["/home/rust/project"]
WORKDIR /home/rust/project
USER rust
