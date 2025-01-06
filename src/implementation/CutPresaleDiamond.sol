// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CutDiamond} from '../../lib/laguna-diamond-foundry/src/diamond/CutDiamond.sol';
import {PresaleFragment} from './PresaleFragment.sol';

/// @title Cut Presale Diamond
/// @notice This is a dummy "implementation" contract for ERC-1967 compatibility,
/// @notice this interface is used by block explorers to generate the UI interface.
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
contract CutPresaleDiamond is CutDiamond, PresaleFragment {

}
