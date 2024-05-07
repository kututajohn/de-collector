# Farm Work Chain

## Overview

The `farm_work_chain` module on the Sui blockchain platform is engineered to streamline the management of agricultural labor through a sophisticated decentralized network. This module empowers farmers with robust tools to create detailed work contracts, hire competent workers, manage disputes effectively, and release payments securely. 

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Run a local network](#run-a-local-network)
4. [Configure connectivity to a local node](#configure-connectivity-to-a-local-node)
5. [Create addresses](#create-addresses)
6. [Get localnet SUI tokens](#get-localnet-SUI-tokens)
7. [Build and publish a smart contract](#build-and-publish-a-smart-contract)
   - [Build package](#build-package)
   - [Publish package](#publish-package)
8. [Structs](#structs)
   - [FarmWork](#farmWork)
   - [WorkRecord](#workRecord)
   - [Errors](#errors)
9. [Core Functionalities](#core-functionalities)
   - [Creating Work Contracts](#create_work-)
   - [Bidding and Work hire worker](#hire_worker-)
   - [Work Submission](#submit_work-)
   - [Dispute Resolution](#resolve_dispute-%EF%B8%8F)
   - [Payment Release and Cancellation](#release_payment-)
   - [Cancellation](#cancel_work-)
   - [Add funds to escrow](#add_funds-)
   - [Update Work Details](#update_work_details-)

## Prerequisites
1. Install dependencies by running the following commands:

   - `sudo apt update`
   
   - `sudo apt install curl git-all cmake gcc libssl-dev pkg-config libclang-dev libpq-dev build-essential -y`

2. Install Rust and Cargo

   - `curl https://sh.rustup.rs -sSf | sh`
   
   - source "$HOME/.cargo/env"

3. Install Sui Binaries
   
   - run the command `chmod u+x sui-binaries.sh` to make the file an executable
   
   execute the installation file by running

   - `./sui-binaries.sh "v1.21.0" "devnet" "ubuntu-x86_64"` for Debian/Ubuntu Linux users
   
   - `./sui-binaries.sh "v1.21.0" "devnet" "macos-x86_64"` for Mac OS users with Intel based CPUs
   
   - `./sui-binaries.sh "v1.21.0" "devnet" "macos-arm64"` for Silicon based Mac 

For detailed installation instructions, refer to the [Installation and Deployment](#installation-and-deployment) section in the provided documentation.

## Installation

1. Clone the repo
   ```sh
   git clone https://github.com/warrenshiv/farm-work-chain-move.git
   ```
2. Navigate to the working directory
   ```sh
   cd Farm_Work_Chain
   ```

## Run a local network
To run a local network with a pre-built binary (recommended way), run this command:
```
RUST_LOG="off,sui_node=info" sui-test-validator
```
## Configure connectivity to a local node
Once the local node is running (using `sui-test-validator`), you should the url of a local node - `http://127.0.0.1:9000` (or similar).
Also, another url in the output is the url of a local faucet - `http://127.0.0.1:9123`.

Next, we need to configure a local node. To initiate the configuration process, run this command in the terminal:
```
sui client active-address
```
The prompt should tell you that there is no configuration found:
```
Config file ["/home/codespace/.sui/sui_config/client.yaml"] doesn't exist, do you want to connect to a Sui Full node server [y/N]?
```
Type `y` and in the following prompts provide a full node url `http://127.0.0.1:9000` and a name for the config, for example, `localnet`.

On the last prompt you will be asked which key scheme to use, just pick the first one (`0` for `ed25519`).

After this, you should see the ouput with the wallet address and a mnemonic phrase to recover this wallet. You can save so later you can import this wallet into SUI Wallet.

Additionally, you can create more addresses and to do so, follow the next section - `Create addresses`.


### Create addresses
For this tutorial we need two separate addresses. To create an address run this command in the terminal:
```
sui client new-address ed25519
```
where:
- `ed25519` is the key scheme (other available options are: `ed25519`, `secp256k1`, `secp256r1`)

And the output should be similar to this:
```
╭─────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Created new keypair and saved it to keystore.                                                   │
├────────────────┬────────────────────────────────────────────────────────────────────────────────┤
│ address        │ 0x05db1e318f1e4bc19eb3f2fa407b3ebe1e7c3cd8147665aacf2595201f731519             │
│ keyScheme      │ ed25519                                                                        │
│ recoveryPhrase │ lava perfect chef million beef mean drama guide achieve garden umbrella second │
╰────────────────┴────────────────────────────────────────────────────────────────────────────────╯
```
Use `recoveryPhrase` words to import the address to the wallet app.


### Get localnet SUI tokens
```
curl --location --request POST 'http://127.0.0.1:9123/gas' --header 'Content-Type: application/json' \
--data-raw '{
    "FixedAmountRequest": {
        "recipient": "<ADDRESS>"
    }
}'
```
`<ADDRESS>` - replace this by the output of this command that returns the active address:
```
sui client active-address
```

You can switch to another address by running this command:
```
sui client switch --address <ADDRESS>
```

## Build and publish a smart contract

### Build package
To build tha package, you should run this command:
```
sui move build
```

If the package is built successfully, the next step is to publish the package:
### Publish package
```
sui client publish --gas-budget 100000000 --json
` - `sui client publish --gas-budget 1000000000`
```

## Structs

### FarmWork
   
   ```
   {
      id: UID,
      farmer: address,
      description: vector<u8>,
      required_skills: vector<u8>,
      category: vector<u8>,
      price: u64,
      escrow: Balance<SUI>,
      dispute: bool,
      rating: Option<u64>,
      status: vector<u8>,
      worker: Option<address>,
      workSubmitted: bool,
      created_at: u64,
      deadline: u64,
   }
   ```

### WorkRecord
   ```
   {
      id: UID,
      farmer: address,
      review: vector<u8>,
   }
   ```

### Errors
   
-  EInvalidBid: u64 = 1;
-  EInvalidWork: u64 = 2;
-  EDispute: u64 = 3;
-  EAlreadyResolved: u64 = 4;
-  ENotworker: u64 = 5;
-  EInvalidWithdrawal: u64 = 6;
-  EDeadlinePassed: u64 = 7;
-  EInsufficientEscrow: u64 = 8;

## Core Functionalities

### create_work 🌱

- **Parameters**:
  - description: `vector<u8>`
  - category: `vector<u8>`
  - required_skills: `vector<u8>`
  - price: `u64`
  - clock: `&Clock`
  - duration: `u64`
  - open: `vector<u8>`
  - ctx: `&mut TxContext`

- **Description**: Creates a new work contract with details about the work, skills required, payment terms, and timeline.

- **Errors**:
  - **EInvalidBid**: if a bid is already present or other issues related to bidding occur.

### hire_worker 👷

- **Parameters**:
  - work: `&mut FarmWork`
  - ctx: `&mut TxContext`

- **Description**: Assigns a worker to a specific `FarmWork` if no worker has been hired yet.

- **Errors**:
  - **EInvalidBid**: if there is already a worker assigned.

### submit_work 📤

- **Parameters**:
  - work: `&mut FarmWork`
  - clock: `&Clock`
  - ctx: `&mut TxContext`

- **Description**: Marks the work as submitted by the worker before the deadline.

- **Errors**:
  - **EDeadlinePassed**: if the submission is attempted after the deadline.
  - **EInvalidWork**: if the work does not meet specified requirements.

### resolve_dispute ⚖️

- **Parameters**:
  - work: `&mut FarmWork`
  - resolved: `bool`
  - ctx: `&mut TxContext`

- **Description**: Resolves a dispute between farmer and worker, potentially redistributing escrow funds based on the resolution.

- **Errors**:
  - **EDispute**: if there is no ongoing dispute.
  - **EAlreadyResolved**: if the dispute has already been resolved.
  - **EInvalidBid**: if no worker was ever hired.

### release_payment 💵

- **Parameters**:
  - work: `&mut FarmWork`
  - clock: `&Clock`
  - review: `vector<u8>`
  - ctx: `&mut TxContext`

- **Description**: Releases the escrow payment to the worker upon successful completion and review of the work.

- **Errors**:
  - **EInsufficientEscrow**: if the escrow balance is too low to cover the payment.
  - **EDeadlinePassed**: if the payment is attempted after the work is overdue.
  - **EInvalidWork**: if the work does not meet the completion criteria.

### add_funds 💰

- **Parameters**:
  - work: `&mut FarmWork`
  - amount: `Coin<SUI>`
  - ctx: `&mut TxContext`

- **Description**: Adds additional funds to the escrow for a `FarmWork` to ensure there are sufficient funds to cover the work payment.

- **Errors**:
  - **ENotworker**: if the action is performed by someone other than the farmer.

### cancel_work 🚫

- **Parameters**:
  - work: `&mut FarmWork`
  - ctx: `&mut TxContext`

- **Description**: Cancels the work contract, refunding the funds from escrow if applicable and resetting the work state.

- **Errors**:
  - **ENotworker**: if the cancellation is attempted by someone other than the farmer or hired worker.
  - **EInvalidWithdrawal**: if an invalid attempt is made to withdraw funds.

### update_work_details 📝

- **Parameters**:
  - work: `&mut FarmWork`
  - new_details: `vector<u8>` (Depending on the attribute being updated, e.g., description, price, deadline)
  - ctx: `&mut TxContext`

- **Description**: Updates specific details of the `FarmWork`, such as description, price, or deadline.

- **Errors**:
  - **ENotworker**: if the update is attempted by someone other than the farmer.
# de-collector
