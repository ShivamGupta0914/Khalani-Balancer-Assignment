// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./Interfaces.sol";
library Structs {
    struct BatchSwapStep {
        bytes32 poolId;  // id of the pool to swap with
        uint256 assetInIndex; // The index of the token within assets which to use as an input of this step.
        uint256 assetOutIndex;
        uint256 amount; //The meaning of amount depends on the value of kind which passed to the batchSwap function.
        bytes userData;
    }
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    enum SwapKind {
        GivenIn,
        GivenOut
    }

    // struct SwapRequest {
    //     IVault.SwapKind kind;
    //     IERC20 tokenIn;
    //     IERC20 tokenOut;
    //     uint256 amount;
    //     // Misc data
    //     bytes32 poolId;
    //     uint256 lastChangeBlock;
    //     address from;
    //     address to;
    //     bytes userData;
    // }
//  JoinPool : -
    // struct PoolBalanceChange {
    //     IAsset[] assets;
    //     uint256[] limits;
    //     bytes userData;
    //     bool useInternalBalance;
    // }
    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }
    // struct AddressSet {
    //     // Storage of set values
    //     address[] _values;
    //     // Position of the value in the `values` array, plus 1 because index 0
    //     // means a value is not in the set.
    //     mapping(address => uint256) _indexes;
    // }
}