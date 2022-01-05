pragma solidity >=0.5.0;

interface IPoolService {
    function creditManagers(uint256 id) external view returns (address);

    function creditManagersCount() external view returns (uint256);

    function underlyingToken() external view returns (address);
}
