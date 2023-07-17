ARG PLATFORM="amd64"
ARG VARIANT="2.0.20230621"

FROM --platform=linux/${PLATFORM} mcr.microsoft.com/cbl-mariner/base/core:${VARIANT}

ENV \
    # Unset ASPNETCORE_URLS from aspnet base image
    ASPNETCORE_URLS= \
    # Do not generate certificate
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # Versions
    DOTNET_SDK_VERSION=7.0.306 \
    DOTNET_VERSION=7.0.9 \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # PowerShell telemetry for docker image usage
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetSDK-CBL-Mariner-2.0 \
    # Setup Path
    PATH=$PATH:/usr/share/dotnet

RUN tdnf -y update  \
    && tdnf install -y \
        python3 \
        python3-pip \
        tar \
        curl \
        git \
        awk \
        ca-certificates \
        libicu \
    && tdnf clean all


# Install Python
RUN tdnf -y update \
    && tdnf install -y \
        python3 \
        python3-pip \
    && /usr/bin/python3 -m pip install --upgrade pip

# Install Azure CLI
RUN /usr/bin/pip3 install wheel setuptools pygments azure-cli --upgrade


RUN curl -fSL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Runtime/$DOTNET_VERSION/dotnet-runtime-$DOTNET_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='09552e5ae6ac014dadf17545ff0a30ab32921075a31fb33e7be148c13078e30d097f592ffa1b8d306563aaa3f6302e40c5c0ba815c1473bbd5d72e3bef55d91e' \
    && echo "$dotnet_sha512  dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -oxzf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz

# Install .NET SDK
RUN curl -fSL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='62df9bca9492b3273830e098e787ec3664243989ac03550534599fc331693553660d3cf8bca655f2d1326070dbb7b20b04743eaba77fa9cc69f6f0fddfdebd06' \
    && echo "$dotnet_sha512  dotnet.tar.gz" | sha512sum -c - \
    && tar -oxzf dotnet.tar.gz -C /usr/share/dotnet ./packs ./sdk ./sdk-manifests ./templates ./LICENSE.txt ./ThirdPartyNotices.txt \
    && rm dotnet.tar.gz \
    # Trigger first run experience by running arbitrary cmd
    && dotnet help
