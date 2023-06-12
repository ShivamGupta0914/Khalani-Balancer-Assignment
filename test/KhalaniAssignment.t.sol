// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./Interfaces.sol";
import "./StructLibrary.sol";

contract CounterTest is Test {
    address constant BALANCER_VAULT_ADDRESS = 0xf46DF0f6c91a66bBB14960245eEC280719428EDd;

    address constant TOKEN_ADMIN = 0x04B0Bff8776D8CC0EF00489940afd9654c67E4C7;
    address constant USDC_ETH_MIRROR = 0x47e4F578Baa6A63891Ee5Ba2D08fcf0c5b8d8307;
    address constant USDC_AVAX_MIRROR = 0xb83dca5964b7FF263279c9f5f3E8E38728ea26Ba;
    address constant AXON_TEST_KAI = 0x1Fa37818ae2710C23301D94d2BeE37951C2DD55b;

    address constant AXON_USDCETH_KAI_BPT = 0x1D2BBc35f7aCe0b2132C888552143c3dc54161Ca;
    address constant AXON_USDCAVAX_KAI_BPT = 0x6978997B5b6061A84d77Bd539F4ff9AECf01C27e;

    bytes32 internal AXON_USDCETH_KAI_BPT_POOLID;
    bytes32 internal AXON_USDCAVAX_KAI_BPT_POOLID;

    IAsset[] internal assets = new IAsset[](3);
    Structs.FundManagement internal funds;
    IVault internal vault = IVault(BALANCER_VAULT_ADDRESS);

    /**
     * @dev this function is called before each test function, this function does thr following-
     * - This function mints Tokens from token owner to this contract and approves vault contract.
     * - this function sets value of funds struct. 
     */
    function setUp() public {
        vm.createSelectFork(vm.envString("KHALANI_RPC_URL"));
        AXON_USDCETH_KAI_BPT_POOLID = Ipool(AXON_USDCETH_KAI_BPT).getPoolId();
        AXON_USDCAVAX_KAI_BPT_POOLID = Ipool(AXON_USDCAVAX_KAI_BPT).getPoolId();
        assets[0] = IAsset(USDC_ETH_MIRROR);
        assets[1] = IAsset(AXON_TEST_KAI);
        assets[2] = IAsset(USDC_AVAX_MIRROR);

        funds.sender = address(this);
        funds.fromInternalBalance = false;
        funds.toInternalBalance = false;
        funds.recipient = payable(address(this));

        IERC20 USDC_ETH = IERC20(USDC_ETH_MIRROR);
        IERC20 USDC_AVAX = IERC20(USDC_AVAX_MIRROR);
        IERC20 AXON_KAI = IERC20(AXON_TEST_KAI);

        vm.startPrank(TOKEN_ADMIN);
        USDC_ETH.mint(address(this), 2800000000);
        USDC_AVAX.mint(address(this), 2800000000);
        AXON_KAI.mint(address(this), 2800000000000000);
        vm.stopPrank();

        USDC_ETH.approve(BALANCER_VAULT_ADDRESS, 2800000000);
        USDC_AVAX.approve(BALANCER_VAULT_ADDRESS, 2800000000);
        AXON_KAI.approve(BALANCER_VAULT_ADDRESS, 2800000000000000);
    }

    /**
     * @dev this function swaps USDC_ETh with USDC_AVAX using batch swap function.
     * - we initialize BatchSwapStep struct inside this function and swapping here takes place by first converting USDC_ETH -> AXON_KAI -> USDC_AVAX. 
     */
    function testSwapUSDC_ETH_to_USDC_AVAX() public {
        Structs.SwapKind kind  = Structs.SwapKind.GivenIn;

        Structs.BatchSwapStep memory b1;
        b1.poolId = AXON_USDCETH_KAI_BPT_POOLID;
        b1.assetInIndex = 0;
        b1.assetOutIndex = 1;
        b1.amount = 2800000000;
        b1.userData = bytes("");

        Structs.BatchSwapStep memory b2;
        b2.poolId = AXON_USDCAVAX_KAI_BPT_POOLID;
        b2.assetInIndex = 1;
        b2.assetOutIndex = 2;
        b2.amount = 0;
        b2.userData = bytes("");

        Structs.BatchSwapStep[] memory swaps = new Structs.BatchSwapStep[](2);
        swaps[0] = b1;
        swaps[1] = b2;

        int256[] memory limits;
        limits = vault.queryBatchSwap(kind, swaps, assets, funds);
        limits = addSlippage(limits);

        vault.batchSwap(kind, swaps, assets, funds, limits, block.timestamp + 5 minutes);
    }

    /**
     * @dev this function swaps USDC_ETH to KAI usng single swap.
     */
    function testSingleSwap() public  {
        Structs.SingleSwap memory singleSwap;
        singleSwap.poolId = AXON_USDCETH_KAI_BPT_POOLID;
        singleSwap.kind = Structs.SwapKind.GivenIn;
        singleSwap.assetIn = IAsset(USDC_ETH_MIRROR);
        singleSwap.assetOut = IAsset(AXON_TEST_KAI);
        singleSwap.amount = 2800000000;
        singleSwap.userData = bytes("");

        vault.swap(singleSwap, funds, 2700000000, block.timestamp + 5 minutes);
    }

    /**
     * @dev this function adds liquidity into USDC_ETH_KAI using the batchSwap function by depositing USDC_ETH and AXON_KAI.
     * @return the array of numbers of tokens transferred from this contract and received as BPT to this contract.
     */
    function testAddLiquidityForUSDC_ETH_KAI() public returns(int256[] memory assetDeltas) {
        Structs.SwapKind kind  = Structs.SwapKind.GivenIn;

        Structs.BatchSwapStep memory b1;
        b1.poolId = AXON_USDCETH_KAI_BPT_POOLID;
        b1.assetInIndex = 0;
        b1.assetOutIndex = 2;
        b1.amount = 2800000000;
        b1.userData = bytes("");

        Structs.BatchSwapStep memory b2;
        b2.poolId = AXON_USDCETH_KAI_BPT_POOLID;
        b2.assetInIndex = 1;
        b2.assetOutIndex = 2;
        b2.amount = 2800000000000000;
        b2.userData = bytes("");

        Structs.BatchSwapStep[] memory swaps = new Structs.BatchSwapStep[](2);
        swaps[0] = b1;
        swaps[1] = b2;

        assets[2] = IAsset(AXON_USDCETH_KAI_BPT);

        int256[] memory limits;
        limits = vault.queryBatchSwap(kind, swaps, assets, funds);
        limits = addSlippage(limits);
        assetDeltas = vault.batchSwap(kind, swaps, assets, funds, limits, block.timestamp + 5 minutes);
    }
    /**
     * @dev this function adds liquidity into USDC_AVAX_KAI using the batchSwap function by depositing USDC_AVAX and AXON_KAI.
     * @return the array of numbers of tokens transferred from this contract and received as BPT to this contract.
     */
    function testAddLiquidityForUSDC_AVAX_KAI() public returns(int256[] memory assetDeltas){
        Structs.SwapKind kind  = Structs.SwapKind.GivenIn;

        Structs.BatchSwapStep memory b1;
        b1.poolId = AXON_USDCAVAX_KAI_BPT_POOLID;
        b1.assetInIndex = 2;
        b1.assetOutIndex = 0;
        b1.amount = 2800000000;
        b1.userData = bytes("");

        Structs.BatchSwapStep memory b2;
        b2.poolId = AXON_USDCAVAX_KAI_BPT_POOLID;
        b2.assetInIndex = 1;
        b2.assetOutIndex = 0;
        b2.amount = 2800000000000000;
        b2.userData = bytes("");

        Structs.BatchSwapStep[] memory swaps = new Structs.BatchSwapStep[](2);
        swaps[0] = b1;
        swaps[1] = b2;

        assets[0] = IAsset(AXON_USDCAVAX_KAI_BPT);

        int256[] memory limits;
        limits = vault.queryBatchSwap(kind, swaps, assets, funds);

        limits = addSlippage(limits);
        assetDeltas = vault.batchSwap(kind, swaps, assets, funds, limits, block.timestamp + 5 minutes);
        
        console.logInt(IERC20(AXON_USDCAVAX_KAI_BPT).balanceOf(address(this)));
    }

    /**
     * @dev this function removes the liquidity from the USDC_ETH_KAI pool calls testAddLiquidityForUSDC_ETH_KAI function first to add liquidity. 
     */
    function testRemoveLiquidityForUSDCETH_KAI() public {
        int256[] memory assetDeltas = testAddLiquidityForUSDC_ETH_KAI();

        uint256 bptToken = uint256(-(assetDeltas[2]));
        
        Structs.SwapKind kind  = Structs.SwapKind.GivenIn;

        Structs.BatchSwapStep memory b1;
        b1.poolId = AXON_USDCETH_KAI_BPT_POOLID;
        b1.assetInIndex = 2;
        b1.assetOutIndex = 1;
        b1.amount = bptToken/2;
        b1.userData = bytes("");

        Structs.BatchSwapStep memory b2;
        b2.poolId = AXON_USDCETH_KAI_BPT_POOLID;
        b2.assetInIndex = 2;
        b2.assetOutIndex = 0;
        b2.amount = bptToken - bptToken/2;
        b2.userData = bytes("");

        Structs.BatchSwapStep[] memory swaps = new Structs.BatchSwapStep[](2);
        swaps[0] = b1;
        swaps[1] = b2;

        int256[] memory limits;
        limits = vault.queryBatchSwap(kind, swaps, assets, funds);
        limits = addSlippage(limits);
        vault.batchSwap(kind, swaps, assets, funds, limits, block.timestamp + 5 minutes);
    }

    /**
     * @dev this function removes the liquidity from the USDC_AVAX_KAI pool calls testAddLiquidityForUSDC_AVAX_KAI function first to add liquidity. 
     */
    function testRemoveLiquidityForUSDCAVAX_KAI() public {
        int256[] memory assetDeltas = testAddLiquidityForUSDC_AVAX_KAI();
        uint256 bptToken = uint256((assetDeltas[2]));
        
        Structs.SwapKind kind  = Structs.SwapKind.GivenIn;

        Structs.BatchSwapStep memory b1;
        b1.poolId = AXON_USDCAVAX_KAI_BPT_POOLID;
        b1.assetInIndex = 0;
        b1.assetOutIndex = 1;
        b1.amount = bptToken/2;
        b1.userData = bytes("");

        Structs.BatchSwapStep memory b2;
        b2.poolId = AXON_USDCAVAX_KAI_BPT_POOLID;
        b2.assetInIndex = 0;
        b2.assetOutIndex = 2;
        b2.amount = bptToken - bptToken/2;
        b2.userData = bytes("");

        Structs.BatchSwapStep[] memory swaps = new Structs.BatchSwapStep[](2);
        swaps[0] = b1;
        swaps[1] = b2;

        int256[] memory limits;
        limits = vault.queryBatchSwap(kind, swaps, assets, funds);
        limits = addSlippage(limits);
        vault.batchSwap(kind, swaps, assets, funds, limits, block.timestamp + 5 minutes);
    }

    function addSlippage(int[] memory limits) private pure returns(int[] memory) {
        for (uint256 i = 0; i < 3; i++) {
            limits[i] = limits[i] < 0 ? (limits[i] * 99) / 100 : limits[i];
        }
        return limits;
    }
}