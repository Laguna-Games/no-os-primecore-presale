// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
// forge-ignore: 5574

import {console} from '../../lib/forge-std/src/console.sol';
import {IDiamondCut} from '../../../lib/laguna-diamond-foundry/src/interfaces/IDiamondCut.sol';
import {LibDeploy} from '../../../lib/laguna-diamond-foundry/script/util/LibDeploy.s.sol';
import {PresaleFacet} from '../../../src/facets/PresaleFacet.sol';

library PresaleFacetDeployLib {
    string public constant FACET_NAME = 'PresaleFacetFacet';

    /// @notice Returns the list of public selectors belonging to the PresaleFacetFacet
    /// @return selectors List of selectors
    function getSelectorList() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](30);
        selectors[0] = PresaleFacet.initializePresale.selector;
        selectors[1] = PresaleFacet.buy.selector;
        selectors[2] = PresaleFacet.redeem.selector;
        selectors[3] = PresaleFacet.getDn404Token.selector;
        selectors[4] = PresaleFacet.setDn404Token.selector;
        selectors[5] = PresaleFacet.getTotalPresaleTokens.selector;
        selectors[6] = PresaleFacet.getTotalTokensPurchased.selector;
        selectors[7] = PresaleFacet.getTotalTokensRedeemed.selector;
        selectors[8] = PresaleFacet.getRedeemableBalance.selector;
        selectors[9] = PresaleFacet.getEthCostPerToken.selector;
        selectors[10] = PresaleFacet.getAllowlistMerkleRoot.selector;
        selectors[11] = PresaleFacet.isAddressAllowed.selector;
        selectors[12] = PresaleFacet.getTreasuryAddress.selector;
        selectors[13] = PresaleFacet.setEthCostPerToken.selector;
        selectors[14] = PresaleFacet.setAllowlistMerkleRoot.selector;
        selectors[15] = PresaleFacet.setTreasuryAddress.selector;
        selectors[16] = PresaleFacet.setMaxTokensPerPlayer.selector;
        selectors[17] = PresaleFacet.getMaxTokensPerPlayer.selector;
        selectors[18] = PresaleFacet.setTotalPresaleTokens.selector;
        selectors[19] = PresaleFacet.getPresaleStartTime.selector;
        selectors[20] = PresaleFacet.setPresaleStartTime.selector;
        selectors[21] = PresaleFacet.getRedemptionTimestamp.selector;
        selectors[22] = PresaleFacet.setRedemptionTimestamp.selector;
        selectors[23] = PresaleFacet.getPresaleConfig.selector;
        selectors[24] = PresaleFacet.getPresaleStatus.selector;
        selectors[25] = PresaleFacet.getAvailableTokensBeforeRedemption.selector;
        selectors[26] = PresaleFacet.getRedeemableTokens.selector;
        selectors[27] = PresaleFacet.getAvailableTokensAfterRedemption.selector;
        selectors[28] = PresaleFacet.isPresaleInitialized.selector;
        selectors[29] = PresaleFacet.getPresaleSoldOut.selector;
    }

    /// @notice Creates a FacetCut object for attaching a facet to a Diamond
    /// @dev This method is exposed to allow multiple cuts to be bundled in one call
    /// @param facet The address of the facet to attach
    /// @return cut The `Add` FacetCut object
    function generateFacetCut(address facet) internal pure returns (IDiamondCut.FacetCut memory cut) {
        cut = LibDeploy.facetCutGenerator(facet, getSelectorList());
    }

    /// @notice Deploys a new facet instance
    /// @return facet The address of the deployed facet
    function deployNewInstance() internal returns (address facet) {
        facet = address(new PresaleFacet());
        console.log(string.concat(string.concat('Deployed ', FACET_NAME, ' at: ', LibDeploy.getVM().toString(facet))));
    }

    /// @notice Attaches a PresaleFacetFacet to a diamond
    function attachFacetToDiamond(address diamond, address facet) internal {
        LibDeploy.cutFacetOntoDiamond(FACET_NAME, generateFacetCut(facet), diamond);
    }

    /// @notice Removes the PresaleFacetFacet from a Diamond
    /// @dev NOTE: This is a greedy cleanup - use it to nuke all of an old facet (even if the old version has extra
    /// deprecated endpoints). If you are un-sure please review this code carefully before using it!
    function removeFacetFromDiamond(address diamond) internal {
        LibDeploy.cutFacetOffOfDiamond(FACET_NAME, getSelectorList(), diamond);
    }
}
