# Puncture

A Bitcoin Lightning wallet that uses hole punching and end-to-end encryption to connect to one or more daemon instances that anyone can deploy themselves via a single docker container.

Download the latest android app release from github: 

https://github.com/joschisan/puncture-app/releases/tag/latest

Checkout the daemon implmentation and information how to deploy your own instance at: 

https://github.com/joschisan/puncture

## Features

- **Lightning Network Wallet**: Send and receive Bitcoin over the Lightning Network
- **Hole Punching**: Direct peer-to-peer connections without port forwarding
- **Ed25519 End-to-End Encryption**: Secure client to server communication using Ed25519
- **Built on Iroh**: Uses [Iroh](https://iroh.computer/) for networking and QUIC transport
- **Multi-Instance Support**: Connect to multiple server instances

