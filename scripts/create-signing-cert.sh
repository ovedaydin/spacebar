#!/usr/bin/env bash
# One-time: creates a self-signed code-signing certificate so every release is
# signed by the same identity. macOS then keeps Full Disk Access across updates
# (with ad-hoc signing, users must re-grant it after every update).
#
# Outputs (in ./signing, which is git-ignored, so KEEP A BACKUP; losing it
# means every user re-grants Full Disk Access once):
#   spacebar-signing.p12   import into Keychain / upload as GitHub secret
#   prints the SHA-1 to use as SIGN_IDENTITY
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/signing"
NAME="Spacebar Self-Signed Code Signing"
PASS="${P12_PASSWORD:-$(openssl rand -base64 18)}"
mkdir -p "$OUT"
[[ -f "$OUT/spacebar-signing.p12" ]] && { echo "Already exists: $OUT/spacebar-signing.p12"; exit 1; }

cat > "$OUT/cs.cnf" <<CNF
[req]
distinguished_name=dn
x509_extensions=ext
prompt=no
[dn]
CN=$NAME
[ext]
basicConstraints=critical,CA:false
keyUsage=critical,digitalSignature
extendedKeyUsage=critical,codeSigning
CNF

openssl req -x509 -newkey rsa:2048 -nodes -days 7300 \
    -keyout "$OUT/key.pem" -out "$OUT/cert.pem" -config "$OUT/cs.cnf" 2>/dev/null
legacy=(); openssl pkcs12 -help 2>&1 | grep -q -- -legacy && legacy=(-legacy)
openssl pkcs12 -export "${legacy[@]}" -inkey "$OUT/key.pem" -in "$OUT/cert.pem" \
    -name "$NAME" -out "$OUT/spacebar-signing.p12" -passout "pass:$PASS"
rm -f "$OUT/key.pem" "$OUT/cs.cnf"

SHA1="$(openssl x509 -in "$OUT/cert.pem" -noout -fingerprint -sha1 | cut -d= -f2 | tr -d :)"
echo "$PASS" > "$OUT/p12-password.txt"
echo "$SHA1" > "$OUT/identity.txt"   # build-app.sh picks this up automatically

cat <<MSG

Created $OUT/spacebar-signing.p12

1) Local builds: import into your login keychain:
     security import "$OUT/spacebar-signing.p12" -P "$PASS" -T /usr/bin/codesign
   then build with:
     SIGN_IDENTITY=$SHA1 ./scripts/build-app.sh

2) GitHub → repo Settings → Secrets and variables → Actions → add:
     SIGNING_P12_BASE64   = output of: base64 -i "$OUT/spacebar-signing.p12" | pbcopy
     SIGNING_P12_PASSWORD = $PASS
     SIGN_IDENTITY        = $SHA1

3) Back up the ./signing folder somewhere safe (password manager).
MSG
