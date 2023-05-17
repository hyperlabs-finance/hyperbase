# Hyperbase

**Welcome to Hyperbase: a lightweight multi-factor smart contract account + digital identity and credentialing solution.**

## What is Hyperbase?

Hyperbase is a lightweight multi-factor smart contract that enables users to hold digital assets and participate in identity driven interactions. Instead of expecting newcomers to educate themselves on security best practices Hyperbase is secure by design. High-risk decisions are safeguarded by multi-factor authentication, either requiring the approval of multiple devices or further the approval of multiple team members. 

Associated with Hyperbase accounts is the Hyperbase identity suite, a series of tools for creating digital identities. Using claims, signed attestations asserting that an account has some attribute or attributes, users can build digital identities that allow them to automate their compliance checks and participate in credential-based interactions opening the door to a world of regulated assets.

## Hyperbase

Blockchain technology today is much like the first generation of the web. Even in 2022, blockchain applications make little provision for non-technical users. This design philosophy is perhaps best summarised as “By developers, for developers”. While the technical infrastructure is established and capable of supporting use at scale a relatively small number of key usability issues present a far greater barrier to adoption than the underlying technology. 

It is our conclusion that for blockchain-based applications to achieve mainstream commercial success, the technical infrastructure must be all but invisible to users. Understanding the blockchain must be an optional extra for those who wish to engage on a more sophisticated level rather than a necessary pastime for anyone who wishes to participate.

Furthermore, in the current paradigm, accounts are made and disposed of at will. Privacy may be of great importance, however, the throwaway nature of blockchain accounts has prevented the space from evolving. Without being able to make any meaningful assumptions about the person behind the account it has proven impractical to create user-oriented experiences. 

Our solution is Hyperbase, a smart contract account and digital identity and credentialling solution. Hyperbase accounts provide drastic improvements over current designs by abstracting all the riskiest, most intimidating, and otherwise inconvenient aspects out of the user's experience. Importantly, Hyperbase does so while maintaining the full benefits of decentralisation. This is essential as it ensures that assets belong to their owner and and no one else. 

#### Subdomain Identifiers

Users have come to expect accounts to be identified by names, usernames, handles, or email addresses, all of which provide identification in a simple, comprehensible format. Rather than being identified by a 42-character public key, Hyperbase accounts and objects are identified by subdomains, giving users a clear, comprehensible handle for interactions.

#### Smart Contract Account

At the core of Hyperbase is a smart contract wallet, that functions as a proxy account contract whereby users may execute transactions. Associated with the account is a key-value store that records an arbitrary number of keys. Any one of these keys may execute transactions from the account following the necessary number of approvals.

Multi-signature wallets (“multi-sigs”) are a widely used class of smart contract wallets. The benefits of multi-signature wallets are that they both remove single-point failures and create a multi-factor authentication process that is ideal for high-risk or institutional transactions. Users may configure an optional number of approvals by operation type in order to execute transactions.

#### Local Keys

While many blockchain enthusiasts are fervent believers in the importance of self-custody, it is important to recognise that for the average user, simplicity is a greater priority than control.

{If we do not acknowledge this fact then we will continue to drive users into the hands of cex}

In order to create a simple, accessible experience while preserving self-custody and ensuring that users have direct control over their assets, Hypersurface uses numerous disposable context-specific key pairs. These key pairs are, in effect, standard externally owned account (“EOA”) wallets.

However, they never actually become known to the user as they are simply used to sign transactions locally. As such, these EOA accounts never hold any funds, which are instead held by the user's core identity account. When a user attempts to access their identity account on a new device, a new key pair is created and stored locally on the user's device. Permission is then requested on the identity account from the existing keys to add the new key. This request must then be approved, typically from another device. Once the key is approved it is added to the account.

#### Meta Transactions

A significant barrier to the adoption of blockchain-based applications is the requirement for network fees (“gas”) to be paid on any given transaction. Gas fees present a barrier to onboarding as users must first purchase network tokens, or otherwise, may be required to hold multiple tokens for a single transaction. Meta transactions, often known as relays, are a powerful mechanism that bypasses the need for the (direct) payment of network fees.

Meta transactions allow users to sign messages showing intent but allow a third-party relayer to execute the transaction itself. A payment in the network token will always be necessary to execute a transaction, therefore meta transactions are not technically gasless, however, they do allow a third party to foot the bill. Hyperbase uses the relay to bypass gas fees on all transactions that are covered externally by its revenue model.

In order to execute a transaction from a Hyperbase user account:
1. A request is generated in the browser for a transaction the user would like to execute.
2. The transaction request is signed with their local private key.
3. The transaction request is sent to the Hypersurface relay.
4. The relay wraps the transaction request within another transaction (meta transaction) and submits the transaction to the identity account contract.
5. The identity account contract unwraps the meta-transaction and executes the transaction requested by the user.

### User Account Access

To access a user account the user inputs a personal account subdomain: “alice.smith.hypersurf”
	a. If the user has an account and key:
		i. The local key is used to sign and send the transaction via relay.
	b. If the user has an account but no key:
		i. A new local key is generated and stored on the device.
		ii. The local key is then added as a new signer to a relay transaction.
		iii. This transaction is then confirmed and sent from a key with the appropriate permissions. For example, a user may sign the transaction by adding their smartphone from their laptop.
	c. If the user does not have an account:
		i. A new local key is generated and stored on the device.
		ii. A new Hyperbase is deployed to the blockchain via relay, with the local key added as having top-level privileges.
		iii. The user-selected ENS subdomain is registered to the user's account address.

## Digital Identities

As a platform for regulated interactions, identity plays a fundamental role in the Hypersurface protocol. Identity is crucial in allowing (1) users to engage with one another online with confidence, (2) creating binding legal agreements between parties and (3) enabling smart contracts to validate credentials, thereby automating the process of compliance.

Verifiable digital identities create a powerful resource that enables users to engage broadly across investment, ownership, and governance on the blockchain. Identities are persistent, meaning they may only need to be verified once to open an entire network of opportunities. In this sense, an identity account can be thought of as a digital ID card. Not only is it valid across opportunities but with further standardisation it may be used across the blockchain ecosystem.

Blockchain-based identity accounts enable information to be verified near-instantly by smart contracts. This has significant implications for issuers as it enables the process of compliance and transfer controls to be automated and enforced at the protocol level. With trust secured by a tamper-proof digital environment, compliant parties can participate with greatly reduced friction. There have been a variety of notable attempts over the years to create digital accounts, all of which have fallen short in one way or another. Ideally, accounts would be secure, self-sovereign, identity-driven, and more broadly compatible with the blockchain ecosystem—all while maintaining the simplicity to onboard first-time users.

## Claims

An identity account has no value in and of itself. To build a meaningful picture of the underlying user or organisation, an account needs “claims”. Claims can be summarised as cryptographically signed digital statements, attesting that an account has some property or properties. Claims can either be self-attested, signed by other users or signed by a trusted third-party credentialing solution. As claims are associated with an account an actionable model of identity begins to emerge. Claims create a powerful resource that enables users to engage broadly across investment, ownership, and governance on the blockchain.

Users may sign claims attesting to statements about themselves or other accounts on-chain. As claim signatures can be linked to the account in question this allows users to verify information about an account without having to store it on-chain or cede it with an intermediary. Such digital identities are persistent, meaning they may only need to be verified once to open an entire network of opportunities. In this sense, an identity account can be thought of as something like a digital ID card. Not only is identity valid across opportunities but with further standardisation, it may be used broadly across the blockchain ecosystem.

With trust secured by a tamper-proof digital ledger, compliant parties can participate with greatly reduced friction. Claims enable information to be verified near-instantly, allowing smart contracts to validate the identities of users on-chain. This has significant implications for issuers as it enables transfer controls and compliance to be automated and enforced at the protocol level.

### Claim Verification

We expect claims to play an important part in the Hypersurface ecosystem, taking on a more diverse role as the Hypersurface ecosystem grows. However, initially, claims will be used as a means of verifying statements in credential-related interactions. An example of the verification process for a credential-based interaction is:

1. AcmeKYC creates a Hypersurface account.
2. Hypersurface verifies AcmeKYC as a trusted verifier for KYC and CDD.
3. To participate in one of any number of investment opportunities a prospective investor may need to verify that they are:
a. Identity verified.
b. An accredited investor.
c. A citizen of a given jurisdiction.
4. The prospective investor pays AcmeKYC and begins the KYC process.
5. After a successful KYC process, AcmeKYC signs the appropriate claims for the prospective investor's identity account.
6. When a share transfer is attempted to the prospective investor the compliance smart contract verifies the receiver's claims and approves the transfer.

Beyond whitelisting, claims serve to add trust to interactions, allowing issuers to permit transfers automatically. Whereas previously issuers would have required complete control and would manually verify who becomes a shareholder, claims allow issuers to specify terms that shareholders must meet before they are eligible to receive shares. This enables issuers to automate transfers, which we believe will enable greatly enhanced transferability and liquidity.

## Verifiers

Hypersurface aims to establish a global, integrated, and compliant ecosystem for tokenised assets, starting with tokenised equity. However, with the vast scope and subtleties of regulation across jurisdictions to preserve its status as an infrastructure platform and to provide a solution that is truly decentralised, the Hypersurface protocol will provide a platform for an ecosystem of “verifiers”. Verifiers serve as trusted third parties that provide credentialing solutions for the Hypersurface community.

Rather than introducing itself as a bottleneck, Hypersurface will provide a broad platform and marketplace for organisations to verify statements in a formal capacity. In exchange for economic incentives, which may be paid in fiat currency, protocol tokens or other crypto assets, verifiers issue claim signatures attesting to the accuracy of a given piece of information about identity. Anyone who knows that a trusted verifier has checked and signed a claim can be confident in the accuracy of a claim without needing to verify it themselves.