// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ParallelMintCollection
 * @dev Replaces global incremental counters with bucket sharding to ensure high-velocity concurrent mint paths.
 */
contract ParallelMintCollection is ERC721, Ownable {
    
    // Allocate 8 isolated bucket tracks to process token additions concurrently
    uint256 public constant BUCKETS_COUNT = 8;
    mapping(uint256 => uint256) public bucketCurrentIds;
    
    event ParallelMintConfirmed(address indexed recipient, uint256 indexed tokenId, uint256 bucketId);

    constructor(string memory name, string memory symbol) 
        ERC721(name, symbol) 
        Ownable(msg.sender) 
    {
        // Distribute starting offsets across the distinct tracking lanes
        for (uint256 i = 0; i < BUCKETS_COUNT; i++) {
            bucketCurrentIds[i] = i * 100000;
        }
    }

    /**
     * @notice Mints a token inside an isolated bucket tracking lane to avoid OCC collisions.
     * @param salt Input entropy parameter used to determine the storage bucket target.
     */
    function mintConcurrently(uint256 salt) external {
        uint256 targetBucket = uint256(keccak256(abi.encodePacked(msg.sender, salt))) % BUCKETS_COUNT;
        
        uint256 assignedTokenId = bucketCurrentIds[targetBucket];
        bucketCurrentIds[targetBucket]++; // Modifies an isolated storage slot entry

        _safeMint(msg.sender, assignedTokenId);
        
        emit ParallelMintConfirmed(msg.sender, assignedTokenId, targetBucket);
    }
}
