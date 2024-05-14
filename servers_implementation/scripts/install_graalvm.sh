#!/bin/bash

if [ "${EUID:-$(id -u)}" -ne 0 ]; then echo "Please run as root or with sudo!" && exit; fi

DOWNLOAD_LINK=
GRAALVM_ARCHIVE="$(pwd)/$(basename "${DOWNLOAD_LINK}")"

echo "Downloading GraalVM..."
wget "${DOWNLOAD_LINK}" 2>&1 | grep ERROR

echo "Extracting GraalVM..."
GRAALVM_EXTRACTED=$(tar -tf "${GRAALVM_ARCHIVE}" | head -1 | sed -e 's/\/.*//')
tar -xzf "${GRAALVM_ARCHIVE}"

echo "Moving GraalVM to /usr/lib/jvm..."
mv "$(pwd)/${GRAALVM_EXTRACTED}" /usr/lib/jvm/

echo "Adding GraalVM to alternatives..."
GRAALVM_PATH="/usr/lib/jvm/${GRAALVM_EXTRACTED}"

add_alternative () {
  update-alternatives --install "/usr/bin/${1}" "${1}" "${GRAALVM_PATH}/bin/${1}" 1119
}

# Add alternatives for stuff provided by the OpenJDK
for val in java jjs keytool pack200 rmid rmiregistry unpack200; do
  add_alternative "${val}"
done
# Add alternatives for some GraalVM stuff
for val in gu javac jconsole javadoc jshell; do
  add_alternative "${val}"
done

echo "Installing config file for update-java-alternatives..."
wget -P /usr/lib/jvm/ https://gist.githubusercontent.com/florian-h05/bc5367263733db2c73e843fcd4033631/raw/cedd042455ac1c5077994dada2617b19d962c95d/graalvm-ce-java.jinfo 2>&1 | grep ERROR
sed -i 's/graalvm-ce-java/'"${GRAALVM_EXTRACTED}"'/g' /usr/lib/jvm/graalvm-ce-java.jinfo
mv /usr/lib/jvm/graalvm-ce-java.jinfo "/usr/lib/jvm/.${GRAALVM_EXTRACTED}.jinfo"

echo "Installing VisualVM..."
gu install visualvm > /dev/null
add_alternatives jvisualvm

