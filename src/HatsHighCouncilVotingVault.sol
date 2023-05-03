// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console2 } from "forge-std/Test.sol"; // remove before deploy
import { IHats } from "hats-protocol/Interfaces/IHats.sol";
import { IVotingVault } from "council/interfaces/IVotingVault.sol";

contract HatsHighCouncilVotingVault is IVotingVault {
  /// @dev The pattern of a member DAO voting rep hat
  uint256 internal constant PATTERN = 0x00000001_0001_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
  /// @dev The mask for a member DAO voting rep hat
  uint256 internal constant MASK = 0xFFFFFFFF_FFFF_0000_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
  /// @notice The Hats Protocol contract
  IHats public immutable HATS;

  constructor(IHats hats) {
    HATS = hats;
  }

  /// @inheritdoc IVotingVault
  function queryVotePower(address user, uint256 /* blockNumber */, bytes calldata extraData)// forgefmt: disable-line
    external
    view
    override
    returns (uint256)
  {
    /// @dev `extraData` is the abi-encoded id of `user`'s Member DAO Voting Rep hat
    uint256 votingHat = abi.decode(extraData, (uint256));

    if (isVotingRepHat(votingHat)) {
      // hat balances are either 0 or 1
      return HATS.balanceOf(user, votingHat);
    } else {
      return 0;
    }
  }

  /// @notice Checks if `hatId` is a member DAO voting rep hat
  /// @param hatId The id of the hat to check
  /// @return True if `hatId` is a member DAO voting rep hat
  function isVotingRepHat(uint256 hatId) public pure returns (bool) {
    return (hatId & MASK) == PATTERN;
  }
}
