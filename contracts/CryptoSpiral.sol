// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockWeaveNet {
    address public owner;

    struct Node {
        uint256 id;
        string data;
        address addedBy;
        uint256 timestamp;
    }

    uint256 public nodeCount;
    mapping(uint256 => Node) public nodes;

    event NodeAdded(uint256 id, string data, address addedBy, uint256 timestamp);
    event NodeUpdated(uint256 id, string newData);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied: Only owner allowed");
        _;
    }

    // Core Function 1: Add a new node
    function addNode(string memory _data) public {
        nodeCount++;
        nodes[nodeCount] = Node(nodeCount, _data, msg.sender, block.timestamp);
        emit NodeAdded(nodeCount, _data, msg.sender, block.timestamp);
    }

    // Core Function 2: Get node details
    function getNode(uint256 _id) public view returns (string memory, address, uint256) {
        require(_id > 0 && _id <= nodeCount, "Invalid node ID");
        Node memory n = nodes[_id];
        return (n.data, n.addedBy, n.timestamp);
    }

    // Core Function 3: Update node data (owner only)
    function updateNode(uint256 _id, string memory _newData) public onlyOwner {
        require(_id > 0 && _id <= nodeCount, "Invalid node ID");
        nodes[_id].data = _newData;
        emit NodeUpdated(_id, _newData);
    }
}
