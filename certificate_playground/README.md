This is a self-signed certificate playground. It shows a solution to hosting services with SSL/TLS certificates.

The end goal of this playground is to apply HTTPS to a self-hosted website or service. Instead of configuring SSL on each individual services it uses Nginx Proxy Manager as reverse proxy to offer HTTPS on all self-hosted services.

## An overview
When a browser requests a domain name eg. **mydomain.lan** the domain must be resolved by DNS first. A resolved domain name lets the browser connect to the IP given by the DNS Server eg. **127.0.0.1**. As the browser connects to the IP it embeds the domain requested by the user as well. If the request was made using HTTPS the webserver must offer a certificate to prove it is indeed the host of the domain name **mydomain.lan**. In order for the browser to trust the certificate it must be signed by a trusted certificate authority like letsencrypt.org or Verisign. No public certificate autority will sign a certificate unless it is proven that the webserver is reachable on the domain name using trusted DNS servers. Usually this requires the administrator of the webserver to buy and own a domain name.
Instead of using public certificate authority, we will establish trust within a LAN and allow browsers to trust a self-hosted webservers certificate.

We will use a host machine, either a physical server or our own workstation, to host a proxy service and a docker based LAN network. The proxy service is the front door to each service (eg. Apache HTTPD) on LAN network configured in docker.
When browser requests a domain name that resolves to the IP where Nginx Proxy Manager is running Nginx Proxy Manager then relays the traffic to one of the backend services. What service it relays traffic to is configured within Nginx Proxy Managers user interface at http://localhost:81

## Getting started
### Installation
1. Run the init-docker.sh script to create an internal network called 'certificateplayground'
2. Get the playground up and running by using `docker compose up -d`. This starts all services. Wait for a bit while Nginx Proxy Manager gets running.
3. Access http://localhost:81 to see Nginx Proxy Managers graphical user interface.
4. Create the administrator user and log in.
5. Create a proxy host
   * Domain Names: mydomain.lan
   * Scheme: http
   * Forward Hostname / IP: httpd
   * Forward Port: 80
   * Save
6. Requesting `mydomain.lan` in a browser doesn't work yet. The browser is unable to resolve mydomain.lan to any IP. Let's fix that.

A client DNS lookup is a layered process. First the browser consults a local DNS table within the operating system. If the lookup fails it then requests the DNS server configured to the network interface (usually the ISPs own DNS). If the DNS lookup to the ISP DNS fails another lookup is performed for the TLD (.com, .dk, .org etc.).
To create a DNS entry for .lan we either add it to the host table of the operating system or add an A record to our own DNS server. If we don't host our own DNS, we need to configure the host inside the operating system.
1. Edit hosts file with administrator privileges
   1. Windows: C:\Windows\System32\drivers\etc\hosts
   2. Linux: /etc/hosts
2. Add a new line `127.0.0.1    mydomain.lan` # Resolve to localhost and Nginx Proxy Manager
3. Save the file
4. Open `http://mydomain.lan` and you should see 'Welcome to the Certificate Playground' meaning we have reached Apache HTTPD

### Create a Certificate Authority
Put your Certificate Authority hat on. We need to sign incoming Certificate Signing Requests by using a certificate authority key pair. The client machine must have the public key in its trust store. Ideally those who creates the service certificate (eg. the webserver) and those signing it (the certificate authority) are different organisations, but within a LAN network or development environment it's usually the same organisation or people.
1. Create folder for Certificate Authority files: `mkdir certificate-authority`
2. Hop into that folder `cd certificate-authority`
3. Create private key `openssl genrsa -out lanCA.key 4096`
4. Create public key as a certificate `openssl req -x509 -new -nodes -key lanCA.key -sha256 -days 1825 -out lanCA.crt -subj "/C=DK/ST=State/L=Locality/O=Certificate Playground/CN=Certificate Playground"`
5. We've created our own certificate authority key pair, but in order for clients to trust it each client OS must install the CA public key. This procedure therefore depends on the OS
   * Windows: (I'm guessing) double click and install the certificate file lanCA.crt
   * Ubuntu: 
     1. Add public certificates `sudo apt-get install -y ca-certificates`
     3. Copy certificate into trust store `sudo cp lanCA.crt /usr/local/share/ca-certificates`
     4. Update trust store `sudo update-ca-certificates`
   * Fedora: 
      1. Convert crt to PEM `openssl x509 -in lanCA.crt -out lanCA.pem -outform PEM`
      2. Copy certificate into trust store `sudo mv lanCA.pem /etc/pki/ca-trust/source/anchors`
      3. Update trust store `sudo update-ca-trust`

## Step 1: Create untrusted certificate for mydomain.lan
1. Head back in the certificate_playground folder `cd ..`
2. Create new directory next to *certificate-authority* called *certs* `mkdir certs`
3. Create certificate: `openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./certs/mydomain.key -out ./certs/mydomain.crt -subj "/CN=issuer.local"`
4. In Nginx Proxy Manager 
   * Click **Certificates** tab to upload certificate
   * **Add Certificate** > **Custom certificate**
   * Name: mydomain.lan
   * Certificate Key: browse to certs/mydomain.key
   * Certificate: browse to certs/mydomain.crt
   * Save
6. The certificate is not yet used. Head back to Dashboard > Proxy Hosts
7. Edit mydomain.lan
8. In SSL tab: select mydomain.lan and enable **Force SSL**
9. Open https://mydomain.lan and notice the browser does not trust the certificate offered by Nginx Proxy Manager as it is not signed by any trusted certificate authority

### Step 2: Create 'Certificate Sign Request' for mydomain.lan
1. Create certificate request: `openssl req -new -key certs/mydomain.key -out certs/mydomain.csr`
   * Country Name (2 letter code): DK
   * State Or Province Name (full name): [enter]
   * Locality name: Aalborg
   * Organization Name: Certificate Playground
   * Organizational Unit Name: [enter]
   * Common Name: mydomain.lan
   * Email Address: [enter]
   * A challenge password: [enter]
   * An optional company name: [enter]
2. Create an empty certificate extension file `certs/mydomain.ext` to the request
```bash
echo "authorityKeyIdentifier=keyid,issuer
	basicConstraints=CA:FALSE
	keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
	subjectAltName = @alt_names

	[alt_names]
	DNS.1 = mydomain.lan" >> certs/mydomain.ext
   ```
### Step 3: Certificate authority verifies domain is reachable
LetsEncrypt, GoDaddy and Verisign will verify the domain. However since CA and requester is this case is the same organisation or people, we can skip this step
### Step 4: Sign the service Certificate Request
1. Sign the certificate: `openssl x509 -req -in certs/mydomain.csr -CA certificate-authority/lanCA.crt -CAkey certificate-authority/lanCA.key -CAcreateserial -out certs/mydomain.crt -days 365 -sha256 -extfile certs/mydomain.ext`
2. (Ubuntu) Verify the certificate (should output nothing if OK)
   * `openssl x509 -in /usr/local/share/ca-certificates/lanCA.crt -noout -text | grep -A 1 'X509v3 Basic Constraints's`
3. (Ubuntu) Verify the certificate is signed by CA
   * `openssl verify -CAfile /usr/local/share/ca-certificates/lanCA.crt certs/mydomain.lan.crt`

### Step 5: Upload signed certificate to Proxy Manager
In Nginx Proxy Manager 
   * Click **Certificates** tab to upload certificate
   * **Add Certificate** > **Custom certificate**
   * Name: mydomain.lan (signed)
   * Certificate Key: browse to certs/mydomain.key
   * Certificate: browse to certs/mydomain.crt
   * Save the certificate
   * Edit Proxy Host **mydomain.lan**
   * In SSL tab: select mydomain.lan (signed) make sure **Force SSL** is enabled

## Seeing it in action
1. Restart the browser
2. Open https://mydomain.lan
3. Click HTTPS icon and verify the certificate