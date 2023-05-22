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

  // uint256 public fork;
  // uint256 public BLOCK_NUMBER;

  uint256 public hat;
  uint256 public MATCHING_HAT = 0x00000057_0001_0001_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
  uint256 public NON_MATCHING_HAT = 0x00000056_0001_0001_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;

  address public user = makeAddr("user");
  address public user2 = makeAddr("user2");
  address public rep;
  uint256 public since; // block number
  uint256 public since2; // block number
  uint256 public propBlock; // proposal block number
  uint256 public constant ONE_VOTE = 10 ** 18;

  error AlreadyRep();
  error NotWearingVotingRepHat();

  event NewVotingRep(address newRep, address prevRep, uint256 votingRepHat);

  function setUp() public virtual {
    // create and activate a fork, at BLOCK_NUMBER
    // fork = vm.createSelectFork(vm.rpcUrl("mainnet"), BLOCK_NUMBER);

    // deploy via the script
    Deploy.prepare(false);
    Deploy.run();
  }

  function setRep(address _user) public {
    // it is a voting rep hat
    hat = MATCHING_HAT;
    // user is wearing it
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, _user, hat), abi.encode(true));
    // set the rep
    hhcvv.setVotingRep(_user, hat);
  }
}

contract IsVotingRepHat is HHCVVTest {
  function testFuzz_matchesPattern_true(uint16 id) public {
    vm.assume(id > 0);
    hat = 0x00000057_0001_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 + (uint256(id) << 192);
    console2.log(hat);
    assertTrue(hhcvv.isVotingRepHat(hat));
  }

  function testFuzz_tooChildy_false(uint160 id) public {
    vm.assume(id > 0);
    hat = 0x00000057_0001_0001_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 + uint256(id);
    console2.log(hat);
    assertFalse(hhcvv.isVotingRepHat(hat));
  }

  function testFuzz_wrongTopHat_false(uint32 id) public {
    vm.assume(id != 87);
    hat = 0x00000000_0001_0001_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 + (uint256(id) << 224);
    console2.log(hat);
    assertFalse(hhcvv.isVotingRepHat(hat));
  }

  function testFuzz_wrongLevel1Hat_false(uint16 id) public {
    vm.assume(id > 1);
    hat = 0x00000057_0000_0001_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 + (uint256(id) << 208);
    console2.log(hat);
    assertFalse(hhcvv.isVotingRepHat(hat));
  }

  function testFuzz_wrongLevel3Hat_false(uint16 id) public {
    vm.assume(id > 1);
    hat = 0x00000057_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 + (uint256(id) << 176);
    console2.log(hat);
    assertFalse(hhcvv.isVotingRepHat(hat));
  }

  function test_concrete_false() public { }
}

contract WearsVotingRepHat is HHCVVTest {
  function test_votingRepHat_wearing_true() public {
    // it is a voting rep hat
    hat = MATCHING_HAT;
    // is wearing the hat
    vm.mockCall(
      address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, address(this), hat), abi.encode(true)
    );

    assertTrue(hhcvv.wearsVotingRepHat(address(this), hat));
  }

  function test_votingRepHat_notWearing_false() public {
    // it is a voting rep hat
    hat = MATCHING_HAT;
    // is not wearing the hat
    vm.mockCall(
      address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, address(this), hat), abi.encode(false)
    );

    assertFalse(hhcvv.wearsVotingRepHat(address(this), hat));
  }

  function test_notVotingRepHat_wearing_false() public {
    // it is not a voting rep hat
    hat = NON_MATCHING_HAT;
    // is wearing the hat
    vm.mockCall(
      address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, address(this), hat), abi.encode(true)
    );

    assertFalse(hhcvv.wearsVotingRepHat(address(this), hat));
  }

  function test_notVotingRepHat_notWearing_false() public {
    // it is not a voting rep hat
    hat = NON_MATCHING_HAT;
    // is not wearing the hat
    vm.mockCall(
      address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, address(this), hat), abi.encode(false)
    );

    assertFalse(hhcvv.wearsVotingRepHat(address(this), hat));
  }
}

contract SetVotingRepHat is HHCVVTest {
  function test_wearingVotingRepHat_notRep_succeeds() public {
    // it is a voting rep hat
    hat = MATCHING_HAT;
    // user is wearing it
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(true));
    // user is not already a rep
    (rep, since) = hhcvv.votingReps(hat);
    assertFalse(rep == user, "user is already a rep");

    // set the rep, expecting an event
    vm.expectEmit(true, true, true, true);
    emit NewVotingRep(user, address(0), hat);
    hhcvv.setVotingRep(user, hat);

    // user is now the rep
    (rep, since) = hhcvv.votingReps(hat);
    assertTrue(rep == user, "user did not become the rep");
    assertEq(since, block.number, "since was not set to the current block");
  }

  function test_WearingVotingRepHat_alreadyRep_reverts() public {
    // it is a voting rep hat
    hat = MATCHING_HAT;
    // user is wearing it
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(true));
    // user is already a rep
    hhcvv.setVotingRep(user, hat);
    (rep, since) = hhcvv.votingReps(hat);
    assertTrue(rep == user, "user is not already a rep");

    // attempt to set the rep, expecting a revert
    vm.expectRevert(AlreadyRep.selector);
    hhcvv.setVotingRep(user, hat);

    // ensure the user is still the rep
    (rep, since2) = hhcvv.votingReps(hat);
    assertTrue(rep == user, "user is not still the rep");
    assertEq(since2, since, "since was changed");
  }

  function test_notWearingVotingRepHat_notRep_reverts() public {
    // it is not a voting rep hat
    hat = NON_MATCHING_HAT;
    // user is not wearing it
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(false));
    // user is not already a rep
    (rep, since) = hhcvv.votingReps(hat);
    assertFalse(rep == user, "user is already a rep");

    // attempt to set the rep, expecting a revert
    vm.expectRevert(NotWearingVotingRepHat.selector);
    hhcvv.setVotingRep(user, hat);

    // ensure the user is still not the rep
    (rep, since2) = hhcvv.votingReps(hat);
    assertFalse(rep == user, "user is now the rep");
    assertEq(since2, since, "since was changed");
  }

  function test_notWearingVotingRepHat_alreadyRep_reverts() public {
    // it is a voting rep hat
    hat = MATCHING_HAT;
    // user is initially wearing the hat
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(true));
    // user is already a rep
    hhcvv.setVotingRep(user, hat);
    (rep, since) = hhcvv.votingReps(hat);
    assertTrue(rep == user, "user is not already a rep");

    // now user loses the hat
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(false));

    // attempt to set the rep, expecting a revert
    vm.expectRevert(NotWearingVotingRepHat.selector);
    hhcvv.setVotingRep(user, hat);

    // ensure the user is still the rep
    (rep, since2) = hhcvv.votingReps(hat);
    assertTrue(rep == user, "user is not still the rep");
    assertEq(since2, since, "since was changed");
  }

  function test_wearingVotingRepHat_notRep_replacePrevRep_succeeds() public {
    // it is a voting rep hat
    hat = MATCHING_HAT;
    // user is wearing it
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(true));
    // user is not already a rep
    (rep, since) = hhcvv.votingReps(hat);
    assertFalse(rep == user, "user is already a rep");

    // set the rep, expecting an event
    vm.expectEmit(true, true, true, true);
    emit NewVotingRep(user, address(0), hat);
    hhcvv.setVotingRep(user, hat);

    // user is now the rep
    (rep, since) = hhcvv.votingReps(hat);
    assertTrue(rep == user, "user did not become the rep");

    // now a user2 is wearing the hat

    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user2, hat), abi.encode(true));

    // set user2 as the new rep, expecting an event
    vm.expectEmit(true, true, true, true);
    emit NewVotingRep(user2, user, hat);
    hhcvv.setVotingRep(user2, hat);

    // user2 is now the rep
    (rep, since) = hhcvv.votingReps(hat);
    assertTrue(rep == user2, "user2 did not become the rep");
    assertEq(since, block.number, "since was changed");
  }
}

contract ClaimVotingPower is HHCVVTest {
  function test_wearingVotingRepHat_notRep_succeeds() public {
    // it is a voting rep hat
    hat = MATCHING_HAT;
    // user is wearing it
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(true));
    // user is not already a rep
    (rep, since) = hhcvv.votingReps(hat);
    assertFalse(rep == user, "user is already a rep");

    // set the rep, expecting an event
    vm.expectEmit(true, true, true, true);
    emit NewVotingRep(user, address(0), hat);
    vm.prank(user);
    hhcvv.claimVotingPower(hat);

    (rep, since) = hhcvv.votingReps(hat);
    assertTrue(rep == user, "user did not become the rep");
    assertEq(since, block.number, "since was not set to the current block");
  }

  function test_WearingVotingRepHat_alreadyRep_reverts() public {
    // it is a voting rep hat
    hat = MATCHING_HAT;
    // user is wearing it
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(true));
    // user is already a rep
    hhcvv.setVotingRep(user, hat);
    (rep, since) = hhcvv.votingReps(hat);
    assertTrue(rep == user, "user is not already a rep");

    // attempt to set the rep, expecting a revert
    vm.expectRevert(AlreadyRep.selector);
    vm.prank(user);
    hhcvv.claimVotingPower(hat);

    // ensure the user is still the rep
    (rep, since2) = hhcvv.votingReps(hat);
    assertTrue(rep == user, "user is not still the rep");
    assertEq(since2, since, "since was changed");
  }

  function test_notWearingVotingRepHat_notRep_reverts() public {
    // it is not a voting rep hat
    hat = NON_MATCHING_HAT;
    // user is not wearing it
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(false));
    // user is not already a rep
    (rep, since) = hhcvv.votingReps(hat);
    assertFalse(rep == user, "user is already a rep");

    // attempt to set the rep, expecting a revert
    vm.expectRevert(NotWearingVotingRepHat.selector);
    vm.prank(user);
    hhcvv.claimVotingPower(hat);

    // ensure the user is still not the rep
    (rep, since2) = hhcvv.votingReps(hat);
    assertFalse(rep == user, "user is now the rep");
    assertEq(since2, since, "since was changed");
  }

  function test_notWearingVotingRepHat_alreadyRep_reverts() public {
    // it is a voting rep hat
    hat = MATCHING_HAT;
    // user is initially wearing the hat
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(true));
    // user is already a rep
    hhcvv.setVotingRep(user, hat);
    (rep, since) = hhcvv.votingReps(hat);
    assertTrue(rep == user, "user is not already a rep");

    // now user loses the hat
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(false));

    // attempt to set the rep, expecting a revert
    vm.expectRevert(NotWearingVotingRepHat.selector);
    vm.prank(user);
    hhcvv.claimVotingPower(hat);

    // ensure the user is still the rep
    (rep, since2) = hhcvv.votingReps(hat);
    assertTrue(rep == user, "user is not still the rep");
    assertEq(since2, since, "since was changed");
  }

  function test_wearingVotingRepHat_notRep_replacePrevRep_succeeds() public {
    // it is a voting rep hat
    hat = MATCHING_HAT;
    // user is wearing it
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(true));
    // user is not already a rep
    (rep, since) = hhcvv.votingReps(hat);
    assertFalse(rep == user, "user is already a rep");

    // set the rep, expecting an event
    vm.expectEmit(true, true, true, true);
    emit NewVotingRep(user, address(0), hat);
    hhcvv.setVotingRep(user, hat);

    // user is now the rep
    (rep, since) = hhcvv.votingReps(hat);
    assertTrue(rep == user, "user did not become the rep");

    // now a user2 is wearing the hat
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user2, hat), abi.encode(true));

    // set user2 as the new rep, expecting an event
    vm.expectEmit(true, true, true, true);
    emit NewVotingRep(user2, user, hat);
    vm.prank(user2);
    hhcvv.claimVotingPower(hat);

    // user2 is now the rep
    (rep, since) = hhcvv.votingReps(hat);
    assertTrue(rep == user2, "user2 did not become the rep");
    assertEq(since, block.number, "since was changed");
  }
}

contract IsVotingRep is HHCVVTest {
  function test_wearsRepHat_isRep_sinceBeforeProp_true() public {
    // user wears the rep hat and is the rep
    setRep(user);

    // proposal block is after since
    (rep, since) = hhcvv.votingReps(hat);
    propBlock = since + 1;

    assertTrue(hhcvv.isVotingRep(user, hat, propBlock), "user is not a voting rep");
  }

  function test_wearsRepHat_isRep_sinceAtProp_false() public {
    // user wears the rep hat and is the rep
    setRep(user);

    // proposal block is at since
    (rep, since) = hhcvv.votingReps(hat);
    propBlock = since;

    assertFalse(hhcvv.isVotingRep(user, hat, propBlock), "user is a voting rep");
  }

  function test_wearsRepHat_isRep_sinceAfterProp_false() public {
    // user wears the rep hat and is the rep
    setRep(user);

    // proposal block is before since
    (rep, since) = hhcvv.votingReps(hat);
    propBlock = since - 1;

    assertFalse(hhcvv.isVotingRep(user, hat, propBlock), "user is a voting rep");
  }

  function test_wearsRepHat_notRep_sinceBeforeProp_false() public {
    // user wears the rep hat but is not the rep
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(true));
    // proposal block is after since
    (rep, since) = hhcvv.votingReps(hat);
    propBlock = since + 1;

    assertFalse(hhcvv.isVotingRep(user, hat, propBlock), "user is a voting rep");
  }

  function test_doesNotWearRepHat_isRep_sinceBeforeProp_false() public {
    // user does not wear the rep hat but is the rep
    setRep(user);
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(false));

    // proposal block is after since
    (rep, since) = hhcvv.votingReps(hat);
    propBlock = since + 1;

    assertFalse(hhcvv.isVotingRep(user, hat, propBlock), "user is a voting rep");
  }
}

contract QueryVotePower is HHCVVTest {
  bytes public hatData;

  function test_isVotingRep_oneVote() public {
    // user wears the rep hat and is the rep
    setRep(user);
    // proposal block is after since
    (rep, since) = hhcvv.votingReps(hat);
    propBlock = since + 1;
    // they are the rep
    assertTrue(hhcvv.isVotingRep(user, hat, propBlock), "user is not a voting rep");

    // abi encode the hat id
    hatData = abi.encode(hat);
    // voting power should be 1
    assertEq(hhcvv.queryVotePower(user, propBlock, hatData), ONE_VOTE, "voting power is not ONE_VOTE");
  }

  function test_isNotVotingRep_noVotes() public {
    // user wears the rep hat but is not the rep
    vm.mockCall(address(hats), abi.encodeWithSelector(hats.isWearerOfHat.selector, user, hat), abi.encode(true));
    // proposal block is later
    (rep, since) = hhcvv.votingReps(hat);
    propBlock = since + 1;
    // they are not the rep
    assertFalse(hhcvv.isVotingRep(user, hat, propBlock), "user is a voting rep");

    // abi encode the hat id
    hatData = abi.encode(hat);
    // voting power should be 0
    assertEq(hhcvv.queryVotePower(user, propBlock, hatData), 0, "voting power is not 0");
  }
}
