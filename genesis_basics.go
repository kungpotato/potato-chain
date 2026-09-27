package evmd

import (
	"encoding/json"

	"github.com/cosmos/cosmos-sdk/codec"

	"github.com/cosmos/evm/x/vm"
)

// evmModuleBasic makes `potatod init` write the same EVM genesis as app.DefaultGenesis().
//
// genutil's InitCmd builds genesis from BasicModuleManager, which bypasses
// app.DefaultGenesis(), so upstream evmd ships a genesis WITHOUT the default
// preinstalls (Create2, Multicall3, Permit2, Safe factory, EIP-2935).
type evmModuleBasic struct {
	vm.AppModuleBasic
}

func (evmModuleBasic) DefaultGenesis(cdc codec.JSONCodec) json.RawMessage {
	return cdc.MustMarshalJSON(NewEVMGenesisState())
}
