// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console2 } from "forge-std/Test.sol"; // remove before deploy
import { IHats } from "hats-protocol/Interfaces/IHats.sol";
import { IVotingVault } from "council/interfaces/IVotingVault.sol";

contract HatsHighCouncilVotingVault is IVotingVault {
  /*//////////////////////////////////////////////////////////////
                          CUSTOM ERRORS
  //////////////////////////////////////////////////////////////*/

  error AlreadyRep();
  error NotVotingRepHatWearer();

  /*//////////////////////////////////////////////////////////////
                          PUBLIC CONSTANTS
  //////////////////////////////////////////////////////////////*/

  /// @notice The Hats Protocol contract
  IHats public immutable HATS;

  /*//////////////////////////////////////////////////////////////
                          INTERNAL CONSTANTS
  //////////////////////////////////////////////////////////////*/

  /// @dev The ERC20-like value for a single vote;
  uint256 internal constant ONE_VOTE = 10 ** 18;
  /// @dev The pattern of a member DAO voting rep hat, i.e. hat 87.1.x.1
  uint256 internal constant PATTERN = 0x00000057_0001_0000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
  /// @dev The mask for a member DAO voting rep hat
  uint256 internal constant MASK = 0xFFFFFFFF_FFFF_0000_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;

  /*//////////////////////////////////////////////////////////////
                            DATA MODELS
  //////////////////////////////////////////////////////////////*/

  struct VotingRep {
    address rep;
    uint256 setAt; // block number
  }

  /*//////////////////////////////////////////////////////////////
                            MUTABLE STATE
  //////////////////////////////////////////////////////////////*/

  mapping(uint256 votingRepHat => VotingRep rep) public votingReps;

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor(IHats hats) {
    HATS = hats;
  }

  /*//////////////////////////////////////////////////////////////
                      IVOTINGVAULT FUNCTION
  //////////////////////////////////////////////////////////////*/

  /// @inheritdoc IVotingVault
  function queryVotePower(address _user, uint256 _blockNumber, bytes calldata _extraData)// forgefmt: disable-line
    external
    view
    override
    returns (uint256)
  {
    /// @dev `extraData` is the abi-encoded id of `_user`'s Member DAO Voting Rep hat
    uint256 votingHat = abi.decode(_extraData, (uint256));

    /**
     * @dev `_user` only has voting power if...
     * 1. `votingHat` is a valid Member DAO voting rep hat (i.e. it matches `PATTERN`)
     * 2. They are currently wearing `votingHat`
     * 3. And have been set as the rep for `votingHat` since before `_blockNumber`
     */
    return isVotingRep(_user, votingHat, _blockNumber) ? ONE_VOTE : 0;
  }

  /*//////////////////////////////////////////////////////////////
                          PUBLIC FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets `_user` as the rep for a given Member DAO voting rep hat
   * @dev `_user` must be wearing `votingRepHat`, which must be a valid Member DAO voting rep hat
   * @param _user The address to set as the rep
   * @param _votingRepHat The id of the hat to set the rep for
   */
  function setVotingRep(address _user, uint256 _votingRepHat) public {
    // `_user` must be wearing `votingRepHat`, which must be a valid Member DAO voting rep hat
    if (!wearsVotingRepHat(_user, _votingRepHat)) revert NotVotingRepHatWearer();

    VotingRep storage rep = votingReps[_votingRepHat];
    // `_user` must not already be the rep
    if (rep.rep == _user) revert AlreadyRep();
    // set `_user` as the rep, and record the block number
    rep.rep = _user;
    rep.setAt = block.number;
  }

  /**
   * @notice Claims rep status for a given Member DAO voting rep hat
   * @dev `msg.sender` must be wearing `votingRepHat`, which must be a valid Member DAO voting rep hat
   * @param _votingRepHat The id of the hat to set the rep for
   */
  function claimVotingPower(uint256 _votingRepHat) external {
    setVotingRep(msg.sender, _votingRepHat);
  }

  /*//////////////////////////////////////////////////////////////
                          PUBLIC GETTERS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Checks if `_hatId` is a valid Member DAO voting rep hat
   * @param _hatId The id of the hat to check
   * @return True if `_hatId` is a member DAO voting rep hat
   */
  function isVotingRepHat(uint256 _hatId) public pure returns (bool) {
    return (_hatId & MASK) == PATTERN;
  }

  /**
   * @notice Checks if an address is wearing a valid Member DAO voting rep hat
   * @param _user The address to check
   * @param _hatId The id of the hat to check
   * @return True if `_hatId` is a valid Member DAO voting rep and, and `_user` is wearing it
   */
  function wearsVotingRepHat(address _user, uint256 _hatId) public view returns (bool) {
    return isVotingRepHat(_hatId) && HATS.isWearerOfHat(_user, _hatId);
  }

  /**
   * @notice Checks if an address is a valid Member DAO voting rep, relative to a given `_blockNumber`
   * @param _user The address to check
   * @param _hatId The id of the hat to check
   * @param _blockNumber The block number to check
   * @return True if `_hatId` is a valid Member DAO voting rep, `_user` is currently wearing it, and has been set as the
   * rep since before `_blockNumber`
   */
  function isVotingRep(address _user, uint256 _hatId, uint256 _blockNumber) public view returns (bool) {
    VotingRep storage rep = votingReps[_hatId];
    return wearsVotingRepHat(_user, _hatId) && (rep.rep == _user) && (rep.setAt < _blockNumber);
  }
}
