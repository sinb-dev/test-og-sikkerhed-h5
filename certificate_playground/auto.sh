# Initial setup of Certificate Authority and client
## Remove old stuff
rm -f certs/*
rm -f certificate-authority/*

## Create directories
mkdir -p certificate-authority
mkdir -p certs

## Create certificate authority key pair
cd certificate-authority
openssl genrsa -out lanCA.key 4096
openssl req -x509 -new -nodes -key lanCA.key -sha256 -days 1825 -out lanCA.pem -subj "/C=DK/ST=State/L=Locality/O=Certificate Playground/CN=Certificate Playground"
openssl x509 -in lanCA.pem -inform PEM -out lanCA.crt

## Client: Add public CA key to local trust
if command -v lsb_release >/dev/null 2>&1; then
  distro=$(lsb_release -si 2>/dev/null | grep -Ei 'fedora|ubuntu' || true)
  if echo "$distro" | grep -qi fedora; then
    sudo rm -f /etc/pki/ca-trust/source/anchors/lanCA.pem
    sudo cp lanCA.pem /etc/pki/ca-trust/source/anchors;
    sudo update-ca-trust;
  elif echo "$distro" | grep -qi ubuntu; then
    sudo rm -f /usr/local/share/ca-certificateslanCA.crt
    sudo apt-get install -y ca-certificates
    sudo cp lanCA.crt /usr/local/share/ca-certificates
    sudo update-ca-certificates
  else
    echo "Unknown distribution: ${distro:-$(lsb_release -sd 2>/dev/null || echo 'none')}"
    exit 2
  fi
else
  echo "lsb_release not found"
  exit 3
fi
cd ..

# Step 1: Create untrusted certificate for mydomain.lan
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./certs/mydomain.key -out ./certs/mydomain.crt -subj "/CN=issuer.local"

# Step 2: Create Certificate Sign Request for mydomain.lan
openssl req -new -key certs/mydomain.key -out certs/mydomain.csr
echo "authorityKeyIdentifier=keyid,issuer
	basicConstraints=CA:FALSE
	keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
	subjectAltName = @alt_names

	[alt_names]
	DNS.1 = mydomain.lan" >> certs/mydomain.ext
    
# Step 3: Certificate authorioty verifies domain is reachable (we skip this step, since we're on LAN)

# Step 4: Sign webservers Certificate Request
openssl x509 -req -in certs/mydomain.csr -CA certificate-authority/lanCA.pem -CAkey certificate-authority/lanCA.key -CAcreateserial -out certs/mydomain.crt -days 365 -sha256 -extfile certs/mydomain.ext

## Verify certificate
openssl verify -CAfile /etc/pki/ca-trust/source/anchors/lanCA.pem certs/mydomain.crt
openssl x509 -in /etc/pki/ca-trust/source/anchors/lanCA.pem -noout -text | grep -A 1 'X509v3 Basic Constraints's

# Step 5: Use/Upload certificate to webserver (manual step)