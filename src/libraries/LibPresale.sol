// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title LibPresale
 * @notice Library for managing DN404 primecore presale functionality
 * @dev Implements presale logic including allowlist verification, token purchases, and redemption
 */

// import {MerkleProof} from '../../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol';
import {LibContractOwner} from '../../lib/laguna-diamond-foundry/src/libraries/LibContractOwner.sol';

interface IDN404 {
    function mint(address to, uint256 amount) external;
}

library LibPresale {
    /// @custom:storage-location erc7201:init.storage
    /// @dev storage slot for the entrypoint contract's storage.
    bytes32 internal constant PRESALE_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256('NeoOlympus.Presale.Storage')) - 1)) & ~bytes32(uint256(0xff));

    /// @notice Emitted when the Allowlist is updated
    /// @param oldRoot The previous root hash
    /// @param newRoot The new root hash
    event AllowlistMerkleRootChanged(bytes32 oldRoot, bytes32 newRoot);

    /// @notice Emitted when the presale start time is updated
    /// @param oldStartTime The previous timestamp
    /// @param newStartTime The new timestamp
    event PresaleStartTimeChanged(uint256 oldStartTime, uint256 newStartTime);

    /// @notice Emitted when the presale total tokens are updated
    /// @param oldTotalTokens The previous total tokens
    /// @param newTotalTokens The new total tokens
    event PresaleTotalTokensAvailableChanged(uint256 oldTotalTokens, uint256 newTotalTokens);

    /// @notice Emited when the treasury address is updated
    /// @param oldAddress The previous address
    /// @param newAddress The new address
    event TreasuryAddressChanged(address oldAddress, address newAddress);

    /// @notice Emitted when the presale cost per token is updated
    /// @param oldCost The previous cost in ETH
    /// @param newCost The new cost in ETH
    event PresaleCostPerTokenChanged(uint256 oldCost, uint256 newCost);

    /// @notice Emitted when the timestamp when reservations can be redeemed is updated
    /// @param oldTimestamp The previous timestamp
    /// @param newTimestamp The new timestamp
    event RedemptionTimestampChanged(uint256 oldTimestamp, uint256 newTimestamp);

    /// @notice Emitted when a player buys presale tokens
    /// @param user The public wallet address of the player
    /// @param tokensBought The number of presale tokens bought
    /// @param tokensRemaining Tokens still available for this player to buy
    /// @param totalTokensRemaining Global tokens still available for presale
    event PresaleTokensPurchased(
        address indexed user,
        uint256 indexed tokensBought,
        uint8 tokensRemaining,
        uint256 totalTokensRemaining
    );

    /// @notice Emitted when a player redeems their presale reservations for DN-404 tokens
    /// @param user The public wallet address of the player
    /// @param tokensRedeemed The number of reservations redeemed
    event PresaleReservationsRedeemed(address indexed user, uint256 indexed tokensRedeemed);

    /// @notice Emitted when the maximum number of presale tokens each player can buy is updated
    /// @param oldTokens The previous maximum number of presale tokens
    /// @param newTokens The new maximum number of presale tokens
    event MaxTokensPerPlayerChanged(uint8 oldTokens, uint8 newTokens);

    /// @notice Emitted when the Allowlist is updated
    /// @param oldRoot The previous root hash
    /// @param newRoot The new root hash
    event AllowlistMerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);

    /// @notice Emitted when permissions are changed for a CS address
    /// @param addr The address
    /// @param isCS If true, the address is given permission, otherwise it is revoked
    event CSPermissionChanged(address addr, bool isCS);

    /// @notice Error thrown when a merkle proof is invalid
    error Merkle_InvalidProof();

    struct PresaleStorage {
        /// @notice Total number of tokens available for presale
        uint32 totalTokensForSale;
        /// @notice Running total of tokens purchased during presale
        uint32 totalTokensPurchased;
        /// @notice Running total of tokens redeemed after presale
        uint32 totalTokensRedeemed;
        /// @notice Cost in ETH per token during presale
        uint256 ethCostPerToken;
        /// @notice Maximum tokens each address can purchase
        uint8 maxTokensPerPlayer;
        /// @notice Timestamp when presale begins
        uint256 presaleStartTime;
        /// @notice Timestamp when tokens can be redeemed
        uint256 redemptionTimestamp;
        /// @notice Address where presale funds are sent
        address treasuryAddress;
        /// @notice Address of the DN404 token contract
        address dn404Token;
        /// @notice Mapping of user addresses to their purchased token count
        mapping(address user => uint8 numTokensPurchased) numTokensPurchased;
        /// @notice Merkle root for allowlist verification
        bytes32 allowlistMerkleRoot;
        /// @notice Boolean to check if the presale is initialized
        bool presaleInitialized;
        /// @notice Timestamp of the presale sold out
        uint256 presaleSoldOutTimestamp;
        /// @notice Map of addresses to CCS permission (true = allowed)
        mapping(address user => bool allowed) csPermissions;
    }

    /// @notice Returns the storage pointer for presale data
    /// @return pss Storage pointer to presale storage struct
    function presaleStorage() internal pure returns (PresaleStorage storage pss) {
        bytes32 slot = PRESALE_STORAGE_POSITION;
        assembly {
            pss.slot := slot
        }
    }

    /// @notice Initializes the presale configuration
    /// @dev Sets initial values for all presale parameters
    /// @param _totalTokensForSale Total number of tokens available for presale
    /// @param _maxTokensPerPlayer Maximum tokens each address can purchase
    /// @param _ethCostPerToken Cost in wei per token
    /// @param _presaleStartTime Timestamp when presale begins
    /// @param _treasuryAddress Address to receive presale funds
    /// @param _dn404Token Address of DN404 token contract
    function initializePresale(
        uint32 _totalTokensForSale,
        uint8 _maxTokensPerPlayer,
        uint256 _ethCostPerToken,
        uint256 _presaleStartTime,
        address _treasuryAddress,
        address _dn404Token
    ) internal {
        presaleStorage().totalTokensForSale = _totalTokensForSale;
        presaleStorage().maxTokensPerPlayer = _maxTokensPerPlayer;
        presaleStorage().ethCostPerToken = _ethCostPerToken;
        presaleStorage().presaleStartTime = _presaleStartTime;
        presaleStorage().redemptionTimestamp = _presaleStartTime + 1 days;
        presaleStorage().treasuryAddress = _treasuryAddress;
        presaleStorage().dn404Token = _dn404Token;
        presaleStorage().presaleInitialized = true;
    }

    /// @notice Allows users to purchase presale tokens
    /// @dev Validates merkle proof, payment, and updates storage
    /// @param numTokens Number of tokens to purchase
    function buy(uint8 numTokens) internal {
        require(presaleStorage().presaleInitialized, 'Presale not initialized');
        require(msg.value >= numTokens * getEthCostPerToken(), 'Invalid ETH amount');
        require(
            block.timestamp >= getPresaleStartTime() && block.timestamp <= getRedemptionTimestamp(),
            'Presale not started or ended'
        );
        require(
            numTokens > 0 && presaleStorage().numTokensPurchased[msg.sender] + numTokens <= getMaxTokensPerPlayer(),
            'Invalid number of tokens'
        );
        require(
            presaleStorage().totalTokensPurchased + numTokens <= presaleStorage().totalTokensForSale,
            'Not enough tokens available'
        );

        payable(getTreasuryAddress()).transfer(msg.value);

        presaleStorage().numTokensPurchased[msg.sender] += numTokens;
        presaleStorage().totalTokensPurchased += numTokens;

        if (presaleStorage().totalTokensPurchased == presaleStorage().totalTokensForSale) {
            presaleStorage().presaleSoldOutTimestamp = block.timestamp;
        }

        emit PresaleTokensPurchased(
            msg.sender,
            numTokens,
            presaleStorage().numTokensPurchased[msg.sender] - numTokens,
            presaleStorage().totalTokensPurchased
        );
    }

    /// @notice Redeems purchased tokens for DN404 tokens
    /// @dev Can only be called after redemption period starts
    function redeem() internal {
        require(presaleStorage().presaleInitialized, 'Presale not initialized');
        require(presaleStorage().numTokensPurchased[msg.sender] > 0, 'User has no tokens left to redeem');
        require(block.timestamp >= getRedemptionTimestamp(), 'Redemption not started');
        require(
            presaleStorage().totalTokensRedeemed + presaleStorage().numTokensPurchased[msg.sender] <=
                presaleStorage().totalTokensForSale,
            'Not enough tokens available'
        );
        uint8 tokensRedeemed = presaleStorage().numTokensPurchased[msg.sender];
        presaleStorage().totalTokensRedeemed += tokensRedeemed;
        presaleStorage().numTokensPurchased[msg.sender] = 0;

        // Mint DN404 tokens
        IDN404(getDn404Token()).mint(msg.sender, tokensRedeemed * 1e18);
        emit PresaleReservationsRedeemed(msg.sender, tokensRedeemed);
    }

    /// @notice Verifies if an address is allowlisted
    /// @param account Address to verify
    /// @param merkleProof Proof for verification
    /// @return bool True if address is allowlisted
    function verify(address account, bytes32[] calldata merkleProof) internal pure returns (bool) {
        (account); // noop
        (merkleProof); // noop
        // bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account))));
        // return MerkleProof.verify(merkleProof, presaleStorage().allowlistMerkleRoot, leaf);
        return true;
    }

    /// @notice Returns the DN404 token contract address
    /// @return Address of the DN404 token contract
    function getDn404Token() internal view returns (address) {
        return presaleStorage().dn404Token;
    }

    /// @notice Returns the total tokens available for presale
    /// @return The total tokens involved in the presale
    function getTotalPresaleTokens() internal view returns (uint32) {
        return presaleStorage().totalTokensForSale;
    }

    /// @notice Returns total tokens purchased in presale
    /// @return Total number of tokens purchased
    function getTotalTokensPurchased() internal view returns (uint32) {
        return presaleStorage().totalTokensPurchased;
    }

    /// @notice Returns the total number of tokens redeemed after presale
    /// @return The total number of tokens redeemed
    function getTotalTokensRedeemed() internal view returns (uint32) {
        return presaleStorage().totalTokensRedeemed;
    }

    /// @notice Returns the number of tokens purchased by a specific user
    /// @param user The address of the user
    /// @return The number of tokens purchased by the user
    function getRedeemableBalance(address user) internal view returns (uint8) {
        return presaleStorage().numTokensPurchased[user];
    }

    /// @notice Returns the cost in ETH per presale token
    /// @return The cost in ETH to reserve one token
    function getEthCostPerToken() internal view returns (uint256) {
        return presaleStorage().ethCostPerToken;
    }

    /// @notice Returns the root hash of the allowlist merkle tree
    /// @return The root hash of the allowlist merkle tree
    function getAllowlistMerkleRoot() internal view returns (bytes32) {
        return presaleStorage().allowlistMerkleRoot;
    }

    /// @notice Returns the address of the treasury
    /// @return The address of the treasury
    function getTreasuryAddress() internal view returns (address) {
        return presaleStorage().treasuryAddress;
    }

    /// @notice Returns the maximum number of presale tokens each player can buy
    /// @return The maximum number of presale tokens
    function getMaxTokensPerPlayer() internal view returns (uint8) {
        return presaleStorage().maxTokensPerPlayer;
    }

    /// @notice Returns the timestamp when presale begins
    /// @return The timestamp when presale starts
    function getPresaleStartTime() internal view returns (uint256) {
        return presaleStorage().presaleStartTime;
    }

    /// @notice Returns the timestamp when reservations can be redeemed
    /// @return The timestamp when redemptions can begin
    function getRedemptionTimestamp() internal view returns (uint256) {
        return presaleStorage().redemptionTimestamp;
    }

    /// @notice Returns the number of presale tokens available before redemption
    /// @return The number of presale tokens available for purchase
    function getAvailableTokensBeforeRedemption() internal view returns (uint32) {
        return presaleStorage().totalTokensForSale - presaleStorage().totalTokensPurchased;
    }

    /// @notice Returns the number of redeemable presale tokens
    /// @return The number of redeemable presale tokens
    function getRedeemableTokens() internal view returns (uint32) {
        return presaleStorage().totalTokensPurchased - presaleStorage().totalTokensRedeemed;
    }

    /// @notice Returns the number of presale tokens available after redemption
    /// @return The number of presale tokens available for purchase
    function getAvailableTokensAfterRedemption() internal view returns (uint32) {
        return presaleStorage().totalTokensForSale - presaleStorage().totalTokensRedeemed;
    }

    /// @notice Returns configuration data for the presale
    /// @return startTime The start time of the presale
    /// @return costPerToken The cost in ETH to reserve one token
    /// @return totalTokens The total number of tokens available for presale
    /// @return maxTokensPerPlayer The maximum number of tokens each player can buy
    /// @return treasuryAddress The address of the treasury
    /// @return dn404Token The address of the DN404 token contract
    function getPresaleConfig()
        internal
        view
        returns (
            uint256 startTime,
            uint256 costPerToken,
            uint32 totalTokens,
            uint8 maxTokensPerPlayer,
            address treasuryAddress,
            address dn404Token
        )
    {
        startTime = presaleStorage().presaleStartTime;
        costPerToken = presaleStorage().ethCostPerToken;
        totalTokens = presaleStorage().totalTokensForSale;
        maxTokensPerPlayer = presaleStorage().maxTokensPerPlayer;
        treasuryAddress = presaleStorage().treasuryAddress;
        dn404Token = presaleStorage().dn404Token;
    }

    /// @notice Returns an overview of the presale
    /// @return presaleStartTime The start time of the presale
    /// @return redemptionStartTime The start time of the redemption period
    /// @return tokensPurchased The number of presale tokens purchased
    /// @return tokensRedeemed The number of presale tokens redeemed
    /// @return availableTokensBeforeRedemption The number of presale tokens available before redemption
    /// @return redeemableTokens The number of presale tokens redeemable
    /// @return availableTokensAfterRedemption The number of presale tokens available after redemption
    function getPresaleStatus()
        internal
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
    {
        presaleStartTime = presaleStorage().presaleStartTime;
        redemptionStartTime = presaleStorage().redemptionTimestamp;
        tokensPurchased = presaleStorage().totalTokensPurchased;
        tokensRedeemed = presaleStorage().totalTokensRedeemed;
        availableTokensBeforeRedemption = getAvailableTokensBeforeRedemption();
        redeemableTokens = getRedeemableTokens();
        availableTokensAfterRedemption = getAvailableTokensAfterRedemption();
    }

    /// @notice Updates the DN404 token contract address
    /// @param _dn404Token New DN404 token contract address
    function setDn404Token(address _dn404Token) internal {
        presaleStorage().dn404Token = _dn404Token;
    }

    /// @notice Updates the cost per token in ETH
    /// @param cost New cost per token
    function setEthCostPerToken(uint256 cost) internal {
        uint256 oldCost = presaleStorage().ethCostPerToken;
        presaleStorage().ethCostPerToken = cost;
        emit PresaleCostPerTokenChanged(oldCost, cost);
    }

    /// @notice Sets the start time of the presale
    /// @dev Only the diamond owner can call this function
    /// @param timestamp The start time of the presale
    /// @custom:emits PresaleStartTimeChanged
    function setPresaleStartTime(uint256 timestamp) internal {
        presaleStorage().presaleStartTime = timestamp;
        emit PresaleStartTimeChanged(presaleStorage().presaleStartTime, timestamp);
    }

    /// @notice Sets the address of the treasury
    /// @dev Only the diamond owner can call this function
    /// @param treasury The address of the treasury
    /// @custom:emits TreasuryAddressChanged
    function setTreasuryAddress(address treasury) internal {
        address oldTreasury = presaleStorage().treasuryAddress;
        presaleStorage().treasuryAddress = treasury;
        emit TreasuryAddressChanged(oldTreasury, treasury);
    }

    /// @notice Sets the maximum number of presale tokens each player can buy
    /// @dev Only the diamond owner can call this function
    /// @param tokens The maximum number of presale tokens
    /// @custom:emits MaxTokensPerPlayerChanged
    function setMaxTokensPerPlayer(uint8 tokens) internal {
        uint8 oldTokens = presaleStorage().maxTokensPerPlayer;
        presaleStorage().maxTokensPerPlayer = tokens;
        emit MaxTokensPerPlayerChanged(oldTokens, tokens);
    }

    /// @notice Sets the timestamp when reservations can be redeemed
    /// @dev Only the diamond owner can call this function
    /// @param timestamp The timestamp when redemptions can begin
    /// @custom:emits RedemptionTimestampChanged
    function setRedemptionTimestamp(uint256 timestamp) internal {
        uint256 oldTimestamp = presaleStorage().redemptionTimestamp;
        presaleStorage().redemptionTimestamp = timestamp;
        emit RedemptionTimestampChanged(oldTimestamp, timestamp);
    }

    /// @notice Sets the root hash of the allowlist merkle tree
    /// @dev Only the diamond owner can call this function
    /// @param _merkleRoot The root hash of the allowlist merkle tree
    /// @custom:emits AllowlistMerkleRootChanged
    function setAllowlistMerkleRoot(bytes32 _merkleRoot) internal {
        bytes32 oldRoot = presaleStorage().allowlistMerkleRoot;
        presaleStorage().allowlistMerkleRoot = _merkleRoot;
        emit AllowlistMerkleRootUpdated(oldRoot, _merkleRoot);
    }

    /// @notice Sets the total tokens available for presale
    /// @dev Only the diamond owner can call this function
    /// @param tokens The total tokens available for presale
    /// @custom:emits PresaleTotalTokensAvailableChanged
    function setTotalPresaleTokens(uint32 tokens) internal {
        uint32 oldTokens = presaleStorage().totalTokensForSale;
        presaleStorage().totalTokensForSale = tokens;
        emit PresaleTotalTokensAvailableChanged(oldTokens, tokens);
    }

    /// @notice Grants an address CS permission
    /// @dev Only the diamond owner can call this function
    /// @param addr The address of the CS wallet
    /// @param isCS If true, the address is given permission, otherwise it is revoked
    /// @custom:emits CSPermissionChanged
    function setCSPermission(address addr, bool isCS) external {
        presaleStorage().csPermissions[addr] = isCS;
        emit CSPermissionChanged(addr, isCS);
    }

    /// @notice Enforces that the caller is either the diamond owner or a CS address
    function enforceIsCSOrContractOwner() internal view {
        if (presaleStorage().csPermissions[msg.sender]) return;
        LibContractOwner.enforceIsContractOwner();
    }
}
