Core Function 1: Add a new node
    function addNode(string memory _data) public {
        nodeCount++;
        nodes[nodeCount] = Node(nodeCount, _data, msg.sender, block.timestamp);
        emit NodeAdded(nodeCount, _data, msg.sender, block.timestamp);
    }

    Core Function 3: Update node data (owner only)
    function updateNode(uint256 _id, string memory _newData) public onlyOwner {
        require(_id > 0 && _id <= nodeCount, "Invalid node ID");
        nodes[_id].data = _newData;
        emit NodeUpdated(_id, _newData);
    }
}
// 
update
// 
