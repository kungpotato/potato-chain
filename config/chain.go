package config

// potato-chain identity. Changing any of these after genesis requires a new chain.
const (
	// ChainID is the Cosmos (CometBFT) chain-id string.
	ChainID = "potato-1"
	// EVMChainID is the EIP-155 chain id used by wallets (MetaMask). Checked free on chainlist.
	EVMChainID uint64 = 707070
	// BaseDenom is the smallest unit (18 decimals, like wei).
	BaseDenom = "apotato"
	// DisplayDenom is the human-facing unit: 1 potato = 10^18 apotato.
	DisplayDenom = "potato"
	// Decimals of DisplayDenom relative to BaseDenom.
	Decimals = 18
)
