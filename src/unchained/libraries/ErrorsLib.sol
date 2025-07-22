// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title ErrorsLib
 * @author Your Name
 * @notice Defines custom errors for the Unchained protocol.
 */
library ErrorsLib {
    // --- General Errors ---
    string public constant NOT_OWNER = "Unchained: Caller is not the owner";
    string public constant ALREADY_SET = "Unchained: Value is already set";
    string public constant ZERO_ADDRESS = "Unchained: Address cannot be zero";
    string public constant ZERO_ASSETS = "Unchained: Asset amount cannot be zero";

    // --- Market Errors ---
    string public constant MARKET_ALREADY_CREATED = "Unchained: Credit market already exists";
    string public constant MARKET_NOT_CREATED = "Unchained: Credit market does not exist";
    string public constant IRM_NOT_ENABLED = "Unchained: IRM is not enabled";

    // --- Borrowing/Repaying Errors ---
    string public constant INSUFFICIENT_LIQUIDITY = "Unchained: Not enough liquidity in the market";
    string public constant INVALID_PROOF = "Unchained: The provided ZK proof is invalid";

    // --- Treasury Errors ---
    string public constant INSUFFICIENT_FUNDS = "Unchained: Insufficient funds in treasury for this market";
}
