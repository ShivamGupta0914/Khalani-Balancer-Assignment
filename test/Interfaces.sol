// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./StructLibrary.sol";

interface IAsset {

}

interface IVault {
     
    function batchSwap(
        Structs.SwapKind kind,
        Structs.BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        Structs.FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    )
        external
        payable
        returns (int256[] memory assetDeltas);

    function queryBatchSwap(
        Structs.SwapKind kind,
        Structs.BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        Structs.FundManagement memory funds
    ) external returns (int256[] memory);

    function swap(
        Structs.SingleSwap memory singleSwap,
        Structs.FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    )external returns (uint256 amountCalculated);

     function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        Structs.JoinPoolRequest memory request
    ) external;
}

interface Ipool {
    function getPoolId() external view returns(bytes32);
    function getVault() external view returns(address);
}

interface IERC20 {
    function mint(address to, uint256 amount) external;
    function approve(address to, uint256 amount) external;
    function balanceOf(address owner) external returns(int256);
}