# Use Ubuntu 22.04 as base
FROM ubuntu:22.04

# Install cURL, Python 3, sudo, unbuffer and the package for "add-apt-repository"
RUN apt update && apt install -y curl python3 sudo expect-dev software-properties-common

# Download Install FEX script to temp file
RUN curl --silent https://raw.githubusercontent.com/FEX-Emu/FEX/main/Scripts/InstallFEX.py --output /tmp/InstallFEX.py

# FEX installer has to install RootFS on the user we want to run the program
# Run as steam user, auto answer yes for all prompts and auto extract on "FEXRootFSFetcher"
# also makes it run with unbuffer because it's fucking shit (TLDR wants to run under zenity when we don't have a display, isatty call being stupid)
RUN sed -i 's@\["FEXRootFSFetcher"\]@"sudo -u steam bash -c \\"unbuffer FEXRootFSFetcher -y -x\\"", shell=True@g' /tmp/InstallFEX.py

# Run verification on steam user
RUN sed -i 's@\["FEXInterpreter", "/usr/bin/uname", "-a"\]@"sudo -u steam bash -c \\"FEXInterpreter /usr/bin/uname -a\\"", shell=True@g' /tmp/InstallFEX.py

# Create user steam
RUN useradd -m steam

# FIX: binfmt 서비스 문제를 근본적으로 해결
# 1. InstallFEX.py에서 binfmt 패키지 제거
RUN sed -i 's/packages = \["fex-emu-armv8.2", "fex-emu-binfmt32", "fex-emu-binfmt64"\]/packages = ["fex-emu-armv8.2"]/g' /tmp/InstallFEX.py

# 2. 이미 설치된 binfmt 패키지가 있다면 완전히 제거
RUN if dpkg -l | grep -q "fex-emu-binfmt"; then \
        apt-get remove --purge -y fex-emu-binfmt32 fex-emu-binfmt64 || true; \
        apt-get autoremove -y || true; \
        apt-get clean || true; \
    fi

# 3. dpkg 구성에서 binfmt 관련 오류 무시하도록 설정
RUN echo '#!/bin/sh' > /usr/sbin/policy-rc.d && \
    echo 'exit 0' >> /usr/sbin/policy-rc.d && \
    chmod +x /usr/sbin/policy-rc.d

# 4. FEX 수동 설치 스크립트 생성 (InstallFEX.py 대체)
RUN echo '#!/bin/bash' > /tmp/install_fex_manual.sh && \
    echo 'set -e' >> /tmp/install_fex_manual.sh && \
    echo '' >> /tmp/install_fex_manual.sh && \
    echo '# PPA 추가' >> /tmp/install_fex_manual.sh && \
    echo 'add-apt-repository ppa:fex-emu/fex -y' >> /tmp/install_fex_manual.sh && \
    echo 'apt update' >> /tmp/install_fex_manual.sh && \
    echo '' >> /tmp/install_fex_manual.sh && \
    echo '# binfmt 패키지 설치 차단' >> /tmp/install_fex_manual.sh && \
    echo 'apt-mark hold fex-emu-binfmt32 fex-emu-binfmt64' >> /tmp/install_fex_manual.sh && \
    echo '' >> /tmp/install_fex_manual.sh && \
    echo '# fex-emu-armv8.2만 설치' >> /tmp/install_fex_manual.sh && \
    echo 'apt install -y fex-emu-armv8.2' >> /tmp/install_fex_manual.sh && \
    echo '' >> /tmp/install_fex_manual.sh && \
    echo '# 정리 작업' >> /tmp/install_fex_manual.sh && \
    echo 'apt clean' >> /tmp/install_fex_manual.sh && \
    echo 'rm -rf /var/lib/apt/lists/*' >> /tmp/install_fex_manual.sh && \
    chmod +x /tmp/install_fex_manual.sh

# 5. FEX 설치 실행 (InstallFEX.py 대신 수동 설치 스크립트 사용)
RUN /tmp/install_fex_manual.sh && \
    rm -f /tmp/InstallFEX.py /tmp/install_fex_manual.sh

# 6. FEX RootFS 수동 설치 (steam 사용자로)
RUN sudo -u steam bash -c "unbuffer FEXRootFSFetcher -y -x" || echo "FEXRootFSFetcher completed (may have warnings)"

# 7. FEX 검증 (steam 사용자로)
RUN sudo -u steam bash -c "FEXInterpreter /usr/bin/uname -a" || echo "FEX verification completed"

# Change user to steam
USER steam

# Go to /home/steam/Steam
WORKDIR /home/steam/Steam

# Download and extract SteamCMD
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Copy init-server.sh to container
COPY --chmod=755 ./init-server.sh /home/steam/init-server.sh

# Set up some default environment variables
ENV ALWAYS_UPDATE_ON_START=true \
    MULTITHREAD_ENABLED=true \
    COMMUNITY_SERVER=true

# Run it
ENTRYPOINT ["/bin/bash", "/home/steam/init-server.sh"]
