# DeFi Collector Module

The **DeFi Collector** module empowers decentralized finance (DeFi) operations, focusing on collection management. It enables the establishment of entities such as companies, users, trucks, collection requests, and collections. Through robust transaction handling, this module ensures integrity and reliability in managing DeFi collections.

---

## Structural Framework

### Company

- **id**: Unique identifier for the company.
- **name**: Company name.
- **email**: Company email address.
- **phone**: Company contact number.
- **charges**: Company fees.
- **balance**: SUI balance of the company.
- **collections**: Table storing company-related collections.
- **requests**: Table storing collection requests directed to the company.
- **company**: Address of the company.

### Collection

- **id**: Unique identifier for the collection.
- **user**: Address of the associated user.
- **userName**: Name of the user associated with the collection.
- **truck**: Details of the truck involved in the collection.
- **date**: Date of the collection.
- **time**: Time of the collection.
- **district**: Collection district.
- **weight**: Weight of the collection.

### User

- **id**: Unique identifier for the user.
- **name**: User's name.
- **email**: User's email address.
- **homeAddress**: User's home address.
- **balance**: SUI balance of the user.
- **user**: Address of the user.

### Truck

- **id**: Unique identifier for the truck.
- **registration**: Truck's registration number.
- **driverName**: Driver's name.
- **capacity**: Truck's capacity.
- **district**: Truck's operating district.
- **assignedUsers**: Addresses of users assigned to the truck.

### CollectionRequest

- **id**: Unique identifier for the collection request.
- **user**: Address of the user making the request.
- **homeAddress**: Address specified in the request.
- **created_at**: Timestamp of the request creation.

---

### Functional Features

#### create_company

Establishes a new company with provided details, integrating it into the system.

#### create_user

Adds a new user to the system with specified attributes.

#### add_truck

Incorporates a new truck into the system, defining its characteristics.

#### new_collection_request

Initiates a fresh collection request from a user, triggering the collection process.

#### add_collection

Integrates a new collection tied to a company, user, and truck, managing associated parameters.

#### fund_user_account

Allocates funds to a user's account, enhancing financial liquidity.

#### user_check_balance

Verifies the balance of a user's account, ensuring transparency.

#### company_check_balance

Checks the balance of a company, facilitating financial oversight.

#### withdraw_company_balance

Facilitates withdrawal of funds from a company's balance, enabling financial transactions.

#### view_collection_requests

Displays all collection requests directed to a specific company, streamlining operational insights.

#### view_collections

Provides a comprehensive view of all collections associated with a particular company, enhancing managerial awareness.

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

## Installation

1. Clone the repo

   ```sh
   git clone https://github.com/kututajohn/de-collector
   ```

2. Navigate to the working directory

   ```sh
   cd de-collector
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
