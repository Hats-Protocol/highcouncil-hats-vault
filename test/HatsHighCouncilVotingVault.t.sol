// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Test, console2 } from "forge-std/Test.sol";
import { HatsHighCouncilVotingVault } from "../src/HatsHighCouncilVotingVault.sol";
import { Deploy } from "../script/HatsHighCouncilVotingVault.s.sol";

contract HHCVVTest is Deploy, Test {
  // variables inhereted from Deploy script
  // HatsHighCouncilVotingVault public hhcvv;
  // IHats public hats;
  // uint256 public membershipDomain;

  uint256 public fork;
  uint256 public BLOCK_NUMBER;

  function setUp() public virtual {
    // create and activate a fork, at BLOCK_NUMBER
    // fork = vm.createSelectFork(vm.rpcUrl("mainnet"), BLOCK_NUMBER);

    // deploy via the script
    Deploy.prepare(false);
    Deploy.run();
  }
}

contract IsVotingRepHat is HHCVVTest {
  uint256 testValue;

  function testFuzz_matchesPattern_true(uint16 id) public {
    vm.assume(id > 0);
    testValue = 0x00000001_0001_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 + (uint256(id) << 192);
    console2.log(testValue);
    assertTrue(hhcvv.isVotingRepHat(testValue));
  }

  function testFuzz_tooChildy_false(uint160 id) public {
    vm.assume(id > 0);
    testValue = 0x00000001_0001_0001_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 + uint256(id);
    console2.log(testValue);
    assertFalse(hhcvv.isVotingRepHat(testValue));
  }

  function testFuzz_wrongTopHat_false(uint32 id) public {
    vm.assume(id > 1);
    testValue = 0x00000000_0001_0001_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 + (uint256(id) << 224);
    console2.log(testValue);
    assertFalse(hhcvv.isVotingRepHat(testValue));
  }

  function testFuzz_wrongLevel1Hat_false(uint16 id) public {
    vm.assume(id > 1);
    testValue = 0x00000001_0000_0001_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 + (uint256(id) << 208);
    console2.log(testValue);
    assertFalse(hhcvv.isVotingRepHat(testValue));
  }

  function testFuzz_wrongLevel3Hat_false(uint16 id) public {
    vm.assume(id > 1);
    testValue = 0x00000001_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 + (uint256(id) << 176);
    console2.log(testValue);
    assertFalse(hhcvv.isVotingRepHat(testValue));
  }
}
