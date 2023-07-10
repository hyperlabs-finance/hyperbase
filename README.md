# Hyperbase

**Welcome to Hyperbase: a secure, lightweight multi-factor smart contract account.**

Hyperbase is a lightweight multi-factor smart contract that enables users to hold digital assets and participate in identity-driven interactions. Instead of expecting newcomers to educate themselves on security best practices Hyperbase is secure by design. High-risk decisions are safeguarded by multi-factor authentication, either requiring the approval of multiple devices or the approval of multiple team members. 

## Hyperbase.sol

Hyperbase handles key management for the smart contract account, functioning like a multi-signature wallet. Each key for the wallet is a context-specific key pair stored locally on the users device. When new devices are added a key is  created locally and permission is requested from another key on the account to  add the new device/key to the Hyperbase account.

## HyperbaseCore.sol

HyperbaseCore manages the transactions for the Hyperbase account. It records past and pending transactions handles their execution.

## HyperbaseForwarder.sol

HyperbaseForwarder allows users to execute transactions from their Hyperbase account without needing network tokens (ETH, MATIC). Transactions may be executed for free, or the gas for the transaction may be refunded using  the Hypersurface network token.