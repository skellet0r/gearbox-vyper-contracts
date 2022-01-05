pragma solidity >=0.5.0;


interface IContractsRegister {
    function getPools() external view returns(address[] memory);
    function getCreditManagers() external view returns(address[] memory);
}
