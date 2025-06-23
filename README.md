# Puncture

A Lightning Network wallet that uses hole punching and end-to-end encryption to connect to one or more daemon instances that anyone can deploy themselves via docker.

Download the latest android release from github: 

https://github.com/joschisan/puncture_app/releases/download/latest/puncture.apk

Checkout the daemon implmentation and information how to deploy your own at: 

https://github.com/joschisan/puncture

## Features

- **Lightning Network Wallet**: Send and receive Bitcoin over the Lightning Network
- **Hole Punching**: Direct peer-to-peer connections without port forwarding
- **End-to-End Encryption**: Secure communication between client and servers
- **Multi-Instance Support**: Connect to multiple server instances
- **Ed25519 Authentication**: Server instances are identified by their Ed25519 public keys
- **Built on Iroh**: Uses [Iroh](https://iroh.computer/) for networking and QUIC transport
