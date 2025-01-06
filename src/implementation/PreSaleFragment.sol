// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PresaleFragment
 * @notice Fragment for presale management functions
 * @dev Diamond facet implementing presale management functions
 */

contract PresaleFragment {
    /// **********************
    /// * INITIALIZATION *
    /// **********************

    /// @notice Initializes the presale with configuration parameters
    /// @dev Can only be called by contract owner
    /// @param _totalTokensForSale Total tokens available in presale
    /// @param _maxTokensPerPlayer Maximum tokens per address
    /// @param _ethCostPerToken Cost in wei per token
    /// @param _presaleStartTime Timestamp when presale begins (in Unix timestamp format)
    /// @param _treasuryAddress Address to receive presale funds
    /// @param _dn404Token Address of DN404 token contract
    function initializePresale(
        uint32 _totalTokensForSale,
        uint8 _maxTokensPerPlayer,
        uint256 _ethCostPerToken,
        uint256 _presaleStartTime,
        address _treasuryAddress,
        address _dn404Token
    ) external {}

    /// **********************
    /// * CORE PRESALE FUNCTIONS *
    /// **********************

    /// @notice Buy a number of presale tokens
    /// @dev Transaction must include ETH equal to the cost (numTokens * getEthCostPerToken())
    /// @param numTokens The number of presale tokens to buy
    /// @param proof The merkle proof that matches the msg.sender address
    function buy(uint8 numTokens, bytes32[] calldata proof) external payable {}

    /// @notice Redeem all of a user's presale reservations into DN404 tokens
    /// @custom:emits PresaleReservationsRedeemed
    function redeem() external {}

    /// **********************
    /// * DN404 TOKEN MANAGEMENT *
    /// **********************

    /// @notice Returns the DN404 token contract address
    /// @return Address of the DN404 token contract
    function getDn404Token() external view returns (address) {}

    /// @notice Updates the DN404 token contract address
    /// @dev Only callable by contract owner
    /// @param _dn404Token New DN404 token contract address
    function setDn404Token(address _dn404Token) external {}

    /// **********************
    /// * PRESALE CONFIGURATION GETTERS *
    /// **********************

    /// @notice Returns the total tokens available for presale
    /// @return Total number of tokens allocated for presale
    function getTotalPresaleTokens() external view returns (uint32) {}

    /// @notice Returns total tokens purchased in presale
    /// @return Total number of tokens purchased
    function getTotalTokensPurchased() external view returns (uint32) {}

    /// @notice Returns total tokens redeemed after presale
    /// @return Total number of tokens redeemed
    function getTotalTokensRedeemed() external view returns (uint32) {}

    /// @notice Returns number of tokens purchased by specific user
    /// @param user Address to check
    /// @return Number of tokens purchased by user
    function getRedeemableBalance(address user) external view returns (uint32) {}

    /// @notice Returns the cost in ETH per presale token
    /// @return The cost in ETH to reserve one token
    function getEthCostPerToken() external view returns (uint256) {}

    /// @notice Returns the current allowlist merkle root
    /// @return Current merkle root hash
    function getAllowlistMerkleRoot() external view returns (bytes32) {}

    /// @notice Checks if an address is approved for presale
    /// @param account The address to verify
    /// @param proof The merkle proof to verify
    /// @return True if the address is approved
    function isAddressAllowed(address account, bytes32[] calldata proof) external view returns (bool) {}

    /// @notice Returns the treasury address
    /// @return The address of the treasury
    function getTreasuryAddress() external view returns (address) {}

    /// **********************
    /// * PRESALE CONFIGURATION SETTERS *
    /// **********************

    /// @notice Sets the cost in ETH per presale token
    /// @dev Only the diamond owner can call this function
    /// @param cost The cost in wei (1e18 = 1 ETH) to reserve one token
    /// @custom:emits PresaleCostPerTokenChanged
    function setEthCostPerToken(uint256 cost) external {}

    /// @notice Set the root hash of the allowlist merkle tree
    /// @dev Only the diamond owner can call this function
    /// @param _merkleRoot The root hash of the allowlist merkle tree
    /// @custom:emits AllowlistMerkleRootChanged
    function setAllowlistMerkleRoot(bytes32 _merkleRoot) external {}

    /// @notice Sets the treasury address
    /// @dev Only the diamond owner can call this function
    /// @param treasury The address of the treasury
    /// @custom:emits TreasuryAddressChanged
    function setTreasuryAddress(address treasury) external {}

    /// @notice Sets the maximum number of presale tokens each player can buy
    /// @dev Only the diamond owner can call this function
    /// @param tokens The maximum number of presale tokens
    /// @custom:emits MaxTokensPerPlayerChanged
    function setMaxTokensPerPlayer(uint8 tokens) external {}

    /// @notice Returns the maximum number of presale tokens each player can buy
    /// @return The maximum number of presale tokens
    function getMaxTokensPerPlayer() external view returns (uint8) {}

    /// @notice Sets the total tokens available for presale
    /// @dev Only the diamond owner can call this function
    /// @param tokens The total tokens available for presale
    /// @custom:emits PresaleTotalTokensAvailableChanged
    function setTotalPresaleTokens(uint32 tokens) external {}

    /// **********************
    /// * TIME MANAGEMENT *
    /// **********************

    /// @notice Returns the start time of the presale
    /// @return The timestamp when presale begins
    function getPresaleStartTime() external view returns (uint256) {}

    /// @notice Sets the start time of the presale
    /// @dev Only the diamond owner can call this function
    /// @param timestamp The start time of the presale (in Unix timestamp format)
    /// @custom:emits PresaleStartTimeChanged
    function setPresaleStartTime(uint256 timestamp) external {}

    /// @notice Returns the timestamp when reservations can be redeemed
    /// @return The timestamp when redemptions can begin
    function getRedemptionTimestamp() external view returns (uint256) {}

    /// @notice Sets the timestamp when reservations can be redeemed
    /// @dev Only the diamond owner can call this function
    /// @param timestamp The timestamp when redemptions can begin
    /// @custom:emits RedemptionTimestampChanged
    function setRedemptionTimestamp(uint256 timestamp) external {}

    /// **********************
    /// * PRESALE STATUS & INFORMATION *
    /// **********************

    /// @notice Returns configuration data for the presale
    /// @return startTime The start time of the presale
    /// @return costPerToken The cost in ETH to reserve one token
    /// @return totalTokens The total number of tokens
    /// @return maxTokensPerPlayer The maximum number of tokens each player can buy
    /// @return treasuryAddress The address of the treasury
    /// @return dn404Token The address of the DN404 token contract
    function getPresaleConfig()
        external
        view
        returns (
            uint256 startTime,
            uint256 costPerToken,
            uint32 totalTokens,
            uint8 maxTokensPerPlayer,
            address treasuryAddress,
            address dn404Token
        )
    {}

    /// @notice Returns an overview of the presale
    /// @return presaleStartTime The start time of the presale
    /// @return redemptionStartTime The start time of the redemption period
    /// @return tokensPurchased The number of presale tokens purchased
    /// @return tokensRedeemed The number of presale tokens redeemed
    /// @return availableTokensBeforeRedemption The number of presale tokens available before redemption
    /// @return redeemableTokens The number of redeemable presale tokens
    /// @return availableTokensAfterRedemption The number of presale tokens available after redemption
    function getPresaleStatus()
        external
        view
        returns (
            uint256 presaleStartTime,
            uint256 redemptionStartTime,
            uint32 tokensPurchased,
            uint32 tokensRedeemed,
            uint32 availableTokensBeforeRedemption,
            uint32 redeemableTokens,
            uint32 availableTokensAfterRedemption
        )
    {}

    /// @notice Returns the number of presale tokens available before redemption
    /// @return The number of presale tokens available for purchase
    function getAvailableTokensBeforeRedemption() external view returns (uint32) {}

    /// @notice Returns the number of redeemable presale tokens
    /// @return The number of redeemable presale tokens
    function getRedeemableTokens() external view returns (uint32) {}

    /// @notice Returns the number of presale tokens available after redemption
    /// @return The number of presale tokens available for purchase
    function getAvailableTokensAfterRedemption() external view returns (uint32) {}

    /// @notice Returns whether the presale is initialized
    /// @return Whether the presale is initialized
    function isPresaleInitialized() external view returns (bool) {}

    /// @notice Returns the timestamp of the presale sold out
    /// @return The timestamp of the presale sold out
    function getPresaleSoldOut() external view returns (uint256) {}

    /// @notice Grants an address CS permission
    /// @dev Only the diamond owner can call this function
    /// @param addr The address of the CS wallet
    /// @param isCS If true, the address is given permission, otherwise it is revoked
    /// @custom:emits CSPermissionChanged
    function setCSPermission(address addr, bool isCS) external {}

    /// @notice Returns whether the address has CS permission
    /// @param addr The address of the CS wallet
    /// @return True if the address has CS permission
    function getCSPermission(address addr) external view returns (bool) {}
}
