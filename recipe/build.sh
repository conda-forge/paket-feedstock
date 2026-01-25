#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

mkdir -p ${PREFIX}/bin
mkdir -p ${PREFIX}/libexec/${PKG_NAME}
ln -sf ${DOTNET_ROOT}/dotnet ${PREFIX}/bin

# Delete vendored bootstrap paket so it is reinstalled
rm -rf global.json
framework_version="$(dotnet --version | sed -e 's/\..*//g').0"

# Overwrite hardcoded .NET version
sed -i "s?<TargetFrameworks>.*</TargetFrameworks>?<TargetFrameworks>net${framework_version}</TargetFrameworks>?" \
     src/Paket/Paket.fsproj

# Build package with dotnet publish
dotnet tool restore
dotnet tool update paket
dotnet publish --no-self-contained src/Paket/Paket.fsproj --output ${PREFIX}/libexec/${PKG_NAME} --framework net${framework_version} -p:TreatWarningsAsErrors=false
rm -rf ${PREFIX}/libexec/${PKG_NAME}/${PKG_NAME}

# Add bash and batch wrappers
tee ${PREFIX}/bin/paket << EOF
#!/bin/sh
exec \${DOTNET_ROOT}/dotnet exec \${CONDA_PREFIX}/libexec/paket/paket.dll "\$@"
EOF
chmod +x ${PREFIX}/bin/paket

tee ${PREFIX}/bin/paket.cmd << EOF
call %DOTNET_ROOT%\dotnet %CONDA_PREFIX%\libexec\paket\paket.dll %*
EOF

# Download dependency licenses with dotnet-project-licenses
tee ignored_packages.json << EOF
["Mono.Cecil"]
EOF

# Download dependency licenses with dotnet-project-licenses
dotnet-project-licenses --input src/Paket/Paket.fsproj -t -d license-files -ignore ignored_packages.json

rm ${PREFIX}/bin/dotnet
