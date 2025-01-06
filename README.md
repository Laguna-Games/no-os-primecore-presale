# no-os-primecore-presale
Neo Olympus - Presale smart contracts for Prime Core DN-404 token

![Visibility: Open Source](https://img.shields.io/badge/visibility-open%20source-brightgreen)

---

## Setup

1. Install [Foundry](https://book.getfoundry.sh/getting-started/installation)
2. Install project dependencies: `forge install`
   1. If lib/forge-std is empty: `forge install foundry-rs/forge-std`
   2. If lib/laguna-diamond-foundry is empty: `forge install https://github.com/Laguna-Games/laguna-diamond-foundry`
   3. If lib/openzeppelin-contracts is empty: `https://github.com/OpenZeppelin/openzeppelin-contracts`
3. Make a copy of [dotenv.example](dotenv.example) and rename it to `.env`
   1. Edit [.env](.env)
   2. Import or generate a wallet to Foundry (see `cast wallet --help`)
      - Fill in `DEPLOYER_ADDRESS` for a deployer wallet address you will use, and validate it with the `--account <account_name>` option in commands
   3. Fill in any API keys for Etherscan, Basescan, Arbiscan, etc.
4. Load environment variables: `source .env`
5. Compile and test the project: `forge test`
