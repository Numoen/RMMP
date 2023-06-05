// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {PairHelper} from "./helpers/PairHelper.sol";

import {Pair} from "src/periphery/PairAddress.sol";

contract MintTest is Test, PairHelper {
    function setUp() external {
        _setUp();
    }

    function testMintReturnAmounts() external {
        (uint256 amount0, uint256 amount1) = basicMint();

        assertEq(amount0, 1e18);
        assertEq(amount1, 1e18);
    }

    function testMintTokenBalances() external {
        basicMint();

        assertEq(token0.balanceOf(address(this)), 0);
        assertEq(token1.balanceOf(address(this)), 0);

        assertEq(token0.balanceOf(address(pair)), 1e18);
        assertEq(token1.balanceOf(address(pair)), 1e18);
    }

    function testMintTierLiquidityInRange() external {
        basicMint();

        (uint256 liquidity) = pair.tiers(0);

        assertEq(liquidity, 1e18);
    }

    function testMintTierLiquidityOutRange() external {
        token1.mint(address(this), 1e18);
        pair.mint(address(this), 0, -1, -1, 1e18, bytes(""));

        (uint256 liquidity) = pair.tiers(0);

        assertEq(liquidity, 0);
    }

    function testMintTicks() external {
        basicMint();

        (uint256 liquidityGross, int256 liquidityNet) = pair.ticks(keccak256(abi.encodePacked(uint8(0), int24(-1))));
        assertEq(liquidityGross, 1e18);
        assertEq(liquidityNet, 1e18);

        (liquidityGross, liquidityNet) = pair.ticks(keccak256(abi.encodePacked(uint8(0), int24(0))));
        assertEq(liquidityGross, 1e18);
        assertEq(liquidityNet, -1e18);
    }

    function testMintPosition() external {
        basicMint();
        (uint256 liquidity) = pair.positions(keccak256(abi.encodePacked(address(this), uint8(0), int24(-1), int24(0))));

        assertEq(liquidity, 1e18);
    }

    function testMintBadTicks() external {
        vm.expectRevert(Pair.InvalidTick.selector);
        pair.mint(address(this), 0, type(int24).min, 0, 1e18, bytes(""));

        vm.expectRevert(Pair.InvalidTick.selector);
        pair.mint(address(this), 0, 0, type(int24).max, 1e18, bytes(""));

        vm.expectRevert(Pair.InvalidTick.selector);
        pair.mint(address(this), 0, 1, 0, 1e18, bytes(""));
    }

    function testMintBadTier() external {
        vm.expectRevert(Pair.InvalidTier.selector);
        pair.mint(address(this), 10, -1, 0, 1e18, bytes(""));
    }
}

contract BurnTest is Test, PairHelper {
    function setUp() external {
        _setUp();
    }

    function testBurnReturnAmounts() external {
        basicMint();
        (uint256 amount0, uint256 amount1) = basicBurn();

        assertEq(amount0, 1e18);
        assertEq(amount1, 1e18);
    }

    function testBurnTokenAmounts() external {
        basicMint();
        basicBurn();

        assertEq(token0.balanceOf(address(this)), 1e18);
        assertEq(token1.balanceOf(address(this)), 1e18);

        assertEq(token0.balanceOf(address(pair)), 0);
        assertEq(token1.balanceOf(address(pair)), 0);
    }

    function testTierInRange() external {
        basicMint();
        basicBurn();

        (uint256 liquidity) = pair.tiers(0);

        assertEq(liquidity, 0);
    }

    function testTierOutRange() external {
        token1.mint(address(this), 1e18);
        pair.mint(address(this), 0, -1, -1, 1e18, bytes(""));

        pair.burn(address(this), 0, -1, -1, 1e18);

        (uint256 liquidity) = pair.tiers(0);

        assertEq(liquidity, 0);
    }

    function testBurnTicks() external {
        basicMint();
        basicBurn();

        (uint256 liquidityGross, int256 liquidityNet) = pair.ticks(keccak256(abi.encodePacked(uint8(0), int24(-1))));
        assertEq(liquidityGross, 0);
        assertEq(liquidityNet, 0);

        (liquidityGross, liquidityNet) = pair.ticks(keccak256(abi.encodePacked(uint8(0), int24(0))));
        assertEq(liquidityGross, 0);
        assertEq(liquidityNet, 0);
    }

    function testBurnPosition() external {
        basicMint();
        basicBurn();

        (uint256 liquidity) = pair.positions(keccak256(abi.encodePacked(address(this), uint8(0), int24(-1), int24(0))));

        assertEq(liquidity, 0);
    }

    function testBurnBadTicks() external {
        vm.expectRevert(Pair.InvalidTick.selector);
        pair.burn(address(this), 0, type(int24).min, 0, 1e18);

        vm.expectRevert(Pair.InvalidTick.selector);
        pair.burn(address(this), 0, 0, type(int24).max, 1e18);

        vm.expectRevert(Pair.InvalidTick.selector);
        pair.burn(address(this), 0, 1, 0, 1e18);
    }

    function testBurnBadTier() external {
        vm.expectRevert(Pair.InvalidTier.selector);
        pair.burn(address(this), 10, -1, 0, 1e18);
    }
}
