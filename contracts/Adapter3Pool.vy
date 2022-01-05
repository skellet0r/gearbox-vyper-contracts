# @version 0.3.0
"""
@title Gearbox Protocol 3Pool Adapter
@license MIT
@dev Original CurveV1 Adapter written by Gearbox Protocol can be found at
    https://etherscan.io/address/0x8F46a26150a80d5F32DEbC7a37af71Bc4CF16529
"""
from vyper.interfaces import ERC20


interface CurvePool:
    def get_dy(_i: int128, _j: int128, _dx: uint256) -> uint256: view
    def get_virtual_price() -> uint256: view

interface CreditManager:
    def executeOrder(_borrower: address, _target: address, _data: Bytes[160]): nonpayable
    def getCreditAccountOrRevert(_borrower: address) -> address: view
    def provideCreditAccountAllowance(_credit_acct: address, _to_contract: address, _token: address): nonpayable

interface CreditFilter:
    def checkCollateralChange(_credit_acct: address, _token_in: address, _token_out: address, _dx: uint256, _dy: uint256): nonpayable


N_COINS: constant(uint256) = 3

CREDIT_MANAGER: constant(address) = 0xC38478B0A4bAFE964C3526EEFF534d70E1E09017
CREDIT_FILTER: constant(address) = 0xcF223eB26dA2Bf147D01b750d2D2393025cEA7Ca

CURVE_POOL: constant(address) = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7
COINS: constant(address[N_COINS]) = [  # DAI/USDC/USDT
    0x6B175474E89094C44Da98b954EedeAC495271d0F,
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
    0xdAC17F958D2ee523a2206206994597C13D831ec7
]


@external
@nonreentrant("key")
def exchange(_i: int128, _j: int128, _dx: uint256, _min_dy: uint256) -> uint256:
    """
    @notice Exchange an asset on the Curve 3Pool
    @param _i Index of the coin to send
    @param _j Index of the coin to receive
    @param _dx Amount of COINS[_i] to exchange for COINS[_j]
    @param _min_dy The minimum amount of COINS[_j] to receive
    @return dy uint256 The amount received from the exchange
    """
    # fetch credit account
    credit_account: address = CreditManager(CREDIT_MANAGER).getCreditAccountOrRevert(msg.sender)

    # store coin addresses in memory
    coins: address[N_COINS] = COINS
    coin_i: address = coins[_i]
    coin_j: address = coins[_j]

    # fetch the starting balance of the credit account for both the coins
    start_balance: uint256[2] = [
        ERC20(coin_i).balanceOf(credit_account), ERC20(coin_i).balanceOf(credit_account)
    ]

    # perform actual operation
    CreditManager(CREDIT_MANAGER).provideCreditAccountAllowance(credit_account, CURVE_POOL, coin_i)
    CreditManager(CREDIT_MANAGER).executeOrder(
        msg.sender,  # borrower
        CURVE_POOL,  # target smart contract
        _abi_encode(  # calldata
            _i, _j, _dx, _min_dy, method_id=method_id("exchange(int128,int128,uint256,uint256)")
        )
    )

    # fetch the ending balance of the credit account for both the coins
    end_balance: uint256[2] = [
        ERC20(coin_i).balanceOf(credit_account), ERC20(coin_i).balanceOf(credit_account)
    ]
    dy: uint256 = end_balance[1] - start_balance[1]

    CreditFilter(CREDIT_FILTER).checkCollateralChange(
        credit_account,
        coin_i,
        coin_j,
        start_balance[0] - end_balance[0],  # amount sent
        dy,  # amount received
    )

    return dy


@view
@external
def get_dy(_i: int128, _j: int128, _dx: uint256) -> uint256:
    """
    @notice Get the amount of coin `_j` one would receive for swapping `_dx` of coin `_i`
    @param _i The index of the input coin
    @param _j The index of the output coin
    @param _dx The amount of coin `_i` to exchange for coin `_j`
    """
    return CurvePool(CURVE_POOL).get_dy(_i, _j, _dx)


@view
@external
def get_virtual_price() -> uint256:
    """
    @notice Query the virtual price of the 3Pool LP token
    """
    return CurvePool(CURVE_POOL).get_virtual_price()

# CONSTANT GETTERS

@view
@external
def coins(_i: uint256) -> address:
    """
    @notice Query the coin at index `_i` for the Curve 3Pool
    @param _i Index of the coin of interest
    """
    coins: address[N_COINS] = COINS
    return coins[_i]


@view
@external
def creditFilter() -> address:
    """
    @notice Query the Credit Filter contract
    """
    return CREDIT_FILTER


@view
@external
def creditManager() -> address:
    """
    @notice Query the Credit Manager contract
    """
    return CREDIT_MANAGER


@view
@external
def curvePool() -> address:
    """
    @notice Query the Curve 3Pool address
    """
    return CURVE_POOL
