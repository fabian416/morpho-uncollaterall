// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title IUnchained
 * @author Your Name
 * @notice This is the primary interface for the Unchained protocol.
 * It defines the core data structures, events, and functions.
 */

// --- Data Structures ---

/**
 * @notice A unique identifier for a credit market.
 * @dev It is the keccak256 hash of the CreditMarketParams.
 */
 
type Id is bytes32;

/**
 * @notice Defines the parameters of an isolated credit market.
 * @param loanToken The address of the token being lent and borrowed.
 * @param creditProofSystem The identifier for the ZK proof system required for this market.
 *                          (e.g., keccak256("ZK_KYC_CREDIT_SCORE_750"))
 * @param irm The address of the Interest Rate Model contract for this market.
 */
struct CreditMarketParams {
    address loanToken;
    bytes32 creditProofSystem;
    address irm;
}

/**
 * @notice Represents the state of a credit market.
 * @param totalSupplyAssets The total amount of assets supplied by the protocol treasury.
 * @param totalBorrowAssets The total amount of assets borrowed by users.
 * @param lastUpdate The timestamp of the last interest accrual.
 */
struct CreditMarket {
    uint128 totalSupplyAssets;
    uint128 totalBorrowAssets;
    uint128 lastUpdate;
}

/**
 * @notice Represents a user's position in a specific credit market.
 * @param borrowAssets The total assets borrowed by the user.
 */
struct Position {
    uint128 borrowAssets;
}

// --- Interfaces ---

interface IUnchained {
    // --- Events ---

    event CreateCreditMarket(Id indexed id, CreditMarketParams marketParams);
    event Borrow(Id indexed id, address indexed borrower, address indexed receiver, uint256 assets);
    event Repay(Id indexed id, address indexed payer, address indexed borrower, uint256 assets);
    event FundMarket(Id indexed id, address indexed funder, uint256 assets);
    event WithdrawFunding(Id indexed id, address indexed receiver, uint256 assets);

    // --- Functions ---

    function createCreditMarket(CreditMarketParams calldata marketParams) external;

    function borrow(
        Id calldata id,
        uint256 assets,
        address receiver,
        bytes calldata proofData // The ZK proof data
    ) external returns (uint256);

    function repay(Id calldata id, uint256 assets, address onBehalf) external returns (uint256);

    // --- Treasury Management ---
    // These functions are for the protocol owner to manage the lending capital.

    function fundMarket(Id calldata id, uint256 assets) external;

    function withdrawFunding(Id calldata id, uint256 assets, address receiver) external;
}

/**
 * @notice Interface for a stateful Interest Rate Model (IRM).
 */
interface IIrm {
    function borrowRate(CreditMarketParams calldata marketParams, CreditMarket calldata market)
        external
        view
        returns (uint256);
}
