// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { Script, console2 } from "forge-std/Script.sol";
import { HatsHighCouncilVotingVault } from "../src/HatsHighCouncilVotingVault.sol";
import { IHats } from "hats-protocol/Interfaces/IHats.sol";

contract Deploy is Script {
  HatsHighCouncilVotingVault public hhcvv;
  bytes32 public SALT = keccak256("lets add some salt to this meal");
  IHats public constant hats = IHats(0x9D2dfd6066d5935267291718E8AA16C8Ab729E9d); // v1.hatsprotocol.eth
  // uint256 public membershipDomain = 0x00000001_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
  // // hat 1.1

  // default values
  bool private verbose = true;

  /// @notice Override default values, if desired
  function prepare(bool _verbose) public {
    verbose = _verbose;
  }

  function run() public {
    uint256 privKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.rememberKey(privKey);
    vm.startBroadcast(deployer);

    hhcvv = new HatsHighCouncilVotingVault{ salt: SALT}(hats);

    vm.stopBroadcast();

    if (verbose) {
      console2.log("Counter:", address(hhcvv));
    }
  }
}

// forge script script/Deploy.s.sol -f ethereum --broadcast --verify
