package evmd

import (
	"context"

	storetypes "github.com/cosmos/cosmos-sdk/store/v2/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	upgradetypes "github.com/cosmos/cosmos-sdk/x/upgrade/types"
)

// UpgradeName is the on-chain plan name a MsgSoftwareUpgrade proposal must use to trigger
// this binary's migration (see scripts/upgrade_drill.sh, docs/12-gov-upgrade.png).
const UpgradeName = "potato-v2"

// UpgradeBlockMaxGas is the new consensus block gas limit set by the potato-v2 upgrade
// (genesis uses 10M; visible to wallets as eth_getBlockByNumber.gasLimit).
const UpgradeBlockMaxGas int64 = 30_000_000

func (app EVMD) RegisterUpgradeHandlers() {
	app.UpgradeKeeper.SetUpgradeHandler(
		UpgradeName,
		func(ctx context.Context, plan upgradetypes.Plan, fromVM module.VersionMap) (module.VersionMap, error) {
			sdkCtx := sdk.UnwrapSDKContext(ctx)

			params, err := app.ConsensusParamsKeeper.ParamsStore.Get(ctx)
			if err != nil {
				return nil, err
			}
			old := params.Block.MaxGas
			params.Block.MaxGas = UpgradeBlockMaxGas
			if err := app.ConsensusParamsKeeper.ParamsStore.Set(ctx, params); err != nil {
				return nil, err
			}
			sdkCtx.Logger().Info("potato-v2: raised block max gas", "from", old, "to", UpgradeBlockMaxGas, "height", plan.Height)

			return app.ModuleManager.RunMigrations(ctx, app.Configurator(), fromVM)
		},
	)

	upgradeInfo, err := app.UpgradeKeeper.ReadUpgradeInfoFromDisk()
	if err != nil {
		panic(err)
	}

	if upgradeInfo.Name == UpgradeName && !app.UpgradeKeeper.IsSkipHeight(upgradeInfo.Height) {
		// potato-v2 adds/removes no modules; list new store keys here in future upgrades.
		storeUpgrades := storetypes.StoreUpgrades{}
		app.SetStoreLoader(upgradetypes.UpgradeStoreLoader(upgradeInfo.Height, &storeUpgrades))
	}
}
