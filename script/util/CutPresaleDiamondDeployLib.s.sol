// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
// forge-ignore: 5574

import {console} from '../../lib/forge-std/src/console.sol';
import {CutPresaleDiamond} from '../../src/implementation/CutPresaleDiamond.sol';
import {DiamondProxyFacet} from '../../lib/laguna-diamond-foundry/src/diamond/DiamondProxyFacet.sol';
import {LibDeploy} from '../../lib/laguna-diamond-foundry/script/util/LibDeploy.s.sol';

library CutPresaleDiamondDeployLib {
    string public constant IMPLEMENTATION_NAME = 'CutPresaleDiamond';
    string public constant ENV_NAME = 'CUT_PRESALE_DIAMOND_IMPLEMENTATION';

    /// @notice Returns the address of a deployed CutPresaleDiamond instance to use
    /// @dev Prefers the address from the CLI environment, otherwise deploys a fresh implementation
    /// @return implementation The address of the deployed implementation
    function getInjectedOrNewImplementationInstance() internal returns (address implementation) {
        implementation = LibDeploy.getAddressFromENV(ENV_NAME);

        if (implementation == address(0)) {
            implementation = deployNewInstance();
        } else {
            console.log(
                string.concat(
                    'Using pre-deployed ',
                    IMPLEMENTATION_NAME,
                    ': ',
                    LibDeploy.getVM().toString(implementation)
                )
            );
        }
    }

    /// @notice Deploys a new implementation instance
    /// @return implementation The address of the deployed implementation
    function deployNewInstance() internal returns (address implementation) {
        implementation = address(new CutPresaleDiamond());
        console.log(
            string.concat(
                string.concat('Deployed ', IMPLEMENTATION_NAME, ' at: ', LibDeploy.getVM().toString(implementation))
            )
        );
    }

    /// @notice Sets the implementation interface on a diamond
    /// @param diamond The address of the diamond to attach the facet to
    /// @param implementation The address of the implementation
    function setImplementationOnDiamond(address diamond, address implementation) internal {
        DiamondProxyFacet(diamond).setImplementation(implementation);
    }
}
