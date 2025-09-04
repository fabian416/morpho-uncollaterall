// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Id, CreditMarketParams } from "../interfaces/IUnchained.sol";

/**
 * @title CreditMarketParamsLib
 * @author Your Name
 * @notice Library to compute the unique ID of a credit market.
 */

library CreditMarketParamsLib {
    /// @notice The length of the data used to compute the id of a market.
    /// @dev The length is 3 * 32 because `CreditMarketParams` has 3 variables of 32 bytes each.
    uint256 internal constant MARKET_PARAMS_BYTES_LENGTH = 3 * 32;

    /**
     * @notice Returns the unique Id of the credit market `marketParams`.
     */
    function id(CreditMarketParams memory marketParams) internal pure returns (Id marketParamsId) {
        assembly ("memory-safe") {
            marketParamsId := keccak256(marketParams, MARKET_PARAMS_BYTES_LENGTH)
        }
    }
}