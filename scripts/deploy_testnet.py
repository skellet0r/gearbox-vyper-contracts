from brownie import (
    Adapter3Pool,
    CurveTokenV2,
    StableSwap3Pool,
    accounts,
    compile_source,
    interface,
)

# Ethereum Mainnet => Kovan Testnet
REPLACEMENTS = {
    # 3Pool
    "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7": "",
    # DAI
    "0x6B175474E89094C44Da98b954EedeAC495271d0F": "0x9DC7B33C3B63fc00ed5472fBD7813eDDa6a64752",
    # USDC
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48": "0x31EeB2d0F9B6fD8642914aB10F4dD473677D80df",
    # USDT
    "0xdAC17F958D2ee523a2206206994597C13D831ec7": "",
}

dev = accounts.load("dev")


def deploy_3pool():
    coins = [interface.ERC20(coin) for coin in list(REPLACEMENTS.values())[-3:]]
    lp_token = CurveTokenV2.deploy("Curve.fi DAI/USDC/USDT", "3CRV", 18, 0, {"from": dev})
    pool = StableSwap3Pool.deploy(dev, coins, lp_token, 100, 4000000, 0, {"from": dev})

    lp_token.set_minter(pool, {"from": dev})

    for coin in coins:
        coin.approve(pool, 2 ** 256 - 1, {"from": dev})

    # seed liquidity
    pool.add_liquidity([coin.balanceOf(dev) for coin in coins], 0, {"from": dev})


def deploy_adapters():
    coins = list(REPLACEMENTS.values())[-3:]

    # an adapter needs to be deployed per gearbox pool
    # (each one has different CreditManager + CreditFilter)
    contracts_register = interface.IContractsRegister("0x2C9c23e06ef59B3A53A8E057c972426B56388339")

    pools = list(map(interface.IPoolService, contracts_register.getPools()))
    credit_managers = list(map(interface.ICreditManager, contracts_register.getCreditManagers()))

    # sanity check - verify deployments are consistent
    assert len(pools) == len(credit_managers)
    for pool, credit_manager in zip(pools, credit_managers):
        assert pool.creditManagersCount() == 1
        assert pool.creditManagers(0) == credit_manager.address

    # deploy adapters
    for pool, credit_manager in zip(pools, credit_managers):
        if pool.underlyingToken() not in coins:
            continue

        src = Adapter3Pool._build["source"]
        for k, v in REPLACEMENTS.items():
            src = src.replace(k, v, 1)
        src = src.replace("0xC38478B0A4bAFE964C3526EEFF534d70E1E09017", credit_manager.address, 1)
        src = src.replace(
            "0xcF223eB26dA2Bf147D01b750d2D2393025cEA7Ca", credit_manager.creditFilter(), 1
        )

        NewAdapter3Pool = compile_source(src, vyper_version="0.3.0").Vyper
        adapter = NewAdapter3Pool.deploy({"from": dev})

        with open(f"{adapter.address}-adapter.vy", "w") as f:
            f.write(src)
