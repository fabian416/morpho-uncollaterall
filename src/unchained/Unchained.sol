// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Id, CreditMarketParams, CreditMarket, Position, IUnchained, IIrm } from "./interfaces/IUnchained.sol";
import { ErrorsLib } from "./libraries/ErrorsLib.sol";
import { CreditMarketParamsLib } from "./libraries/CreditMarketParamsLib.sol";
import { IERC20 } from "../interfaces/IERC20.sol";
import { SafeTransferLib } from "../libraries/SafeTransferLib.sol";

/**
 * @title Unchained
 * @author Your Name
 * @notice The main contract for the Unchained uncollateralized lending protocol.
 * @dev V1 of this protocol assumes the owner is the sole liquidity provider.
 */
contract Unchained is IUnchained {
    using SafeTransferLib for IERC20;
    using CreditMarketParamsLib for CreditMarketParams;

    /* STORAGE */

    address public owner;

    /// @notice Maps a credit market Id to its current state.
    mapping(Id => CreditMarket) public creditMarket;

    /// @notice Maps a credit market Id to a user's position.
    mapping(Id => mapping(address => Position)) public position;

    /// @notice Maps a credit market Id to its defining parameters.
    mapping(Id => CreditMarketParams) public idToCreditMarketParams;

    /// @notice A whitelist of enabled Interest Rate Model contracts.
    mapping(address => bool) public isIrmEnabled;

    /* CONSTRUCTOR */

    constructor(address newOwner) {
        require(newOwner != address(0), ErrorsLib.ZERO_ADDRESS);
        owner = newOwner;
    }

    /* MODIFIERS */

    modifier onlyOwner() {
        require(msg.sender == owner, ErrorsLib.NOT_OWNER);
        _;
    }

    /* OWNER-ONLY FUNCTIONS */

    /**
     * @notice Enables a new Interest Rate Model contract.
     */
    function enableIrm(address irm) external onlyOwner {
        require(!isIrmEnabled[irm], ErrorsLib.ALREADY_SET);
        isIrmEnabled[irm] = true;
    }

    /**
     * @notice The owner (treasury) funds a specific credit market.
     */
    function fundMarket(Id calldata id, uint256 assets) external onlyOwner {
        require(creditMarket[id].lastUpdate != 0, ErrorsLib.MARKET_NOT_CREATED);
        require(assets > 0, ErrorsLib.ZERO_ASSETS);

        creditMarket[id].totalSupplyAssets += uint128(assets);

        emit FundMarket(id, msg.sender, assets);

        IERC20(idToCreditMarketParams[id].loanToken).safeTransferFrom(msg.sender, address(this), assets);
    }

    /**
     * @notice The owner (treasury) withdraws funding from a specific credit market.
     */
    function withdrawFunding(Id calldata id, uint256 assets, address receiver) external onlyOwner {
        require(creditMarket[id].lastUpdate != 0, ErrorsLib.MARKET_NOT_CREATED);
        require(assets > 0, ErrorsLib.ZERO_ASSETS);
        require(receiver != address(0), ErrorsLib.ZERO_ADDRESS);

        creditMarket[id].totalSupplyAssets -= uint128(assets);
        require(creditMarket[id].totalBorrowAssets <= creditMarket[id].totalSupplyAssets, ErrorsLib.INSUFFICIENT_FUNDS);

        emit WithdrawFunding(id, receiver, assets);

        IERC20(idToCreditMarketParams[id].loanToken).safeTransfer(receiver, assets);
    }

    /* MARKET CREATION */

    /**
     * @notice Creates a new isolated credit market.
     */
    function createCreditMarket(CreditMarketParams calldata marketParams) external onlyOwner {
        Id id = marketParams.id();
        require(isIrmEnabled[marketParams.irm], ErrorsLib.IRM_NOT_ENABLED);
        require(creditMarket[id].lastUpdate == 0, ErrorsLib.MARKET_ALREADY_CREATED);

        creditMarket[id].lastUpdate = uint128(block.timestamp);
        idToCreditMarketParams[id] = marketParams;

        emit CreateCreditMarket(id, marketParams);
    }

    /* BORROW & REPAY */

    /**
     * @notice Borrows assets from a credit market after verifying the user's ZK proof.
     */
    function borrow(
        Id calldata id,
        uint256 assets,
        address receiver,
        bytes calldata proofData
    ) external returns (uint256) {
        require(creditMarket[id].lastUpdate != 0, ErrorsLib.MARKET_NOT_CREATED);
        require(assets > 0, ErrorsLib.ZERO_ASSETS);
        require(receiver != address(0), ErrorsLib.ZERO_ADDRESS);

        // TODO: FOCUS HERE
        // This is the most critical part of your protocol.
        // You need to implement the logic to verify the `proofData` against the
        // `creditProofSystem` defined in the `CreditMarketParams` for this market.
        // This will likely involve calling an external verifier contract or using an on-chain library.
        // For now, it just returns true.
        bool isProofValid = _verifyProof(id, msg.sender, proofData);
        require(isProofValid, ErrorsLib.INVALID_PROOF);

        _accrueInterest(id);

        position[id][msg.sender].borrowAssets += uint128(assets);
        creditMarket[id].totalBorrowAssets += uint128(assets);

        require(creditMarket[id].totalBorrowAssets <= creditMarket[id].totalSupplyAssets, ErrorsLib.INSUFFICIENT_LIQUIDITY);

        emit Borrow(id, msg.sender, receiver, assets);

        IERC20(idToCreditMarketParams[id].loanToken).safeTransfer(receiver, assets);

        return assets;
    }

    /**
     * @notice Repays assets to a credit market on behalf of a borrower.
     */
    function repay(Id calldata id, uint256 assets, address onBehalf) external returns (uint256) {
        require(creditMarket[id].lastUpdate != 0, ErrorsLib.MARKET_NOT_CREATED);
        require(assets > 0, ErrorsLib.ZERO_ASSETS);
        require(onBehalf != address(0), ErrorsLib.ZERO_ADDRESS);

        _accrueInterest(id);

        // TODO: You might want to add logic to handle over-repayment.
        position[id][onBehalf].borrowAssets -= uint128(assets);
        creditMarket[id].totalBorrowAssets -= uint128(assets);

        emit Repay(id, msg.sender, onBehalf, assets);

        IERC20(idToCreditMarketParams[id].loanToken).safeTransferFrom(msg.sender, address(this), assets);

        return assets;
    }

    /* INTERNAL HELPERS */

    /**
     * @dev Verifies the ZK proof for a borrow operation.
     * @dev This is a placeholder and needs to be implemented.
     */
    function _verifyProof(Id id, address borrower, bytes calldata proofData) internal view returns (bool) {
        // TODO: FOCUS HERE
        // 1. Get the `creditProofSystem` from `idToCreditMarketParams[id]`.
        // 2. Decode `proofData`.
        // 3. Call the appropriate ZK verifier contract based on the proof system.
        // 4. Ensure the proof is valid for the `borrower` and the current context.
        // For now, we will just return true for testing purposes.
        return true;
    }

    /**
     * @dev Accrues interest for a given credit market.
     */
    function _accrueInterest(Id id) internal {
        uint256 elapsed = block.timestamp - creditMarket[id].lastUpdate;
        if (elapsed == 0) return;

        CreditMarketParams memory marketParams = idToCreditMarketParams[id];
        if (marketParams.irm != address(0)) {
            // TODO: FOCUS HERE
            // The interest calculation is simplified here. You might need a more robust
            // implementation, especially regarding compounding.
            // The `wTaylorCompounded` function from Morpho's MathLib is a good reference.
            uint256 borrowRate = IIrm(marketParams.irm).borrowRate(marketParams, creditMarket[id]);
            uint256 interest = (creditMarket[id].totalBorrowAssets * borrowRate * elapsed) / (1e18 * 365 days);

            creditMarket[id].totalBorrowAssets += uint128(interest);
        }

        creditMarket[id].lastUpdate = uint128(block.timestamp);
    }
}
