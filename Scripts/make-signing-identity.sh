#!/bin/bash
# Creates a self-signed "Melatonin Self-Signed" code-signing identity in the
# login keychain. Builds signed with it keep the same identity, so macOS keeps
# Location access and keychain approvals across updates. Run once per Mac.
set -euo pipefail

if security find-identity -p codesigning | grep -q '"Melatonin Self-Signed"'; then
    echo "Melatonin Self-Signed already exists."
    exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"
cat > cfg <<'CFG'
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = Melatonin Self-Signed
O = Melatonin
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
subjectKeyIdentifier = hash
CFG
PASS="$(/usr/bin/openssl rand -hex 16)"
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 3650 -config cfg 2>/dev/null
/usr/bin/openssl pkcs12 -export -inkey key.pem -in cert.pem -name "Melatonin Self-Signed" -out id.p12 -passout "pass:$PASS"
security import id.p12 -k ~/Library/Keychains/login.keychain-db -P "$PASS" -T /usr/bin/codesign
echo "Created Melatonin Self-Signed."
