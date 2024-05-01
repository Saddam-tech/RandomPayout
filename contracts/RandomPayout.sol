// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomPayout {
    address public owner;
    uint public TOTAL_ADDRESSES;
    uint public SELECTED_ADDRESSES;
    uint public PAYOUT_AMOUNT;

    address[] public participantAddresses;
    address[] public selectedAddresses;

    constructor(
        uint _totalAddresses,
        uint _selectedAddresses,
        uint _payoutAmountWlc
    ) {
        owner = msg.sender;
        TOTAL_ADDRESSES = _totalAddresses;
        SELECTED_ADDRESSES = _selectedAddresses;
        PAYOUT_AMOUNT = _payoutAmountWlc * 1 ether; // Convert amount from Ether to Wei

        participantAddresses = new address[](TOTAL_ADDRESSES);
        selectedAddresses = new address[](SELECTED_ADDRESSES);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // Function to deposit Ether into contract
    function deposit() external payable onlyOwner {
        require(
            msg.value >= SELECTED_ADDRESSES * PAYOUT_AMOUNT,
            "Deposit must cover payouts for the selected addresses."
        );
    }

    // Function to set participant addresses
    function setParticipantAddresses(
        address[] memory addresses
    ) external onlyOwner {
        require(
            addresses.length == TOTAL_ADDRESSES,
            "Must provide the correct number of addresses."
        );
        participantAddresses = addresses;
    }

    // Function to randomly select addresses from participants
    function selectRandomAddresses() external onlyOwner {
        require(
            participantAddresses.length == TOTAL_ADDRESSES,
            "Participant addresses not set properly."
        );

        // Copy participant addresses to a temporary array for shuffling
        address[] memory tempAddresses = new address[](TOTAL_ADDRESSES);
        for (uint i = 0; i < TOTAL_ADDRESSES; i++) {
            tempAddresses[i] = participantAddresses[i];
        }

        // Shuffle addresses and pick the first unique addresses based on SELECTED_ADDRESSES
        for (uint i = 0; i < SELECTED_ADDRESSES; i++) {
            uint rand = random(TOTAL_ADDRESSES - i) + i;
            (tempAddresses[i], tempAddresses[rand]) = (
                tempAddresses[rand],
                tempAddresses[i]
            );
        }

        // Store the first selected addresses
        for (uint i = 0; i < SELECTED_ADDRESSES; i++) {
            selectedAddresses[i] = tempAddresses[i];
        }
    }

    // Function to payout Ether to each selected address
    function executePayout() external onlyOwner {
        require(
            selectedAddresses.length == SELECTED_ADDRESSES,
            "Addresses not yet selected."
        );
        require(
            address(this).balance >= SELECTED_ADDRESSES * PAYOUT_AMOUNT,
            "Insufficient balance for payouts."
        );

        for (uint i = 0; i < SELECTED_ADDRESSES; i++) {
            payable(selectedAddresses[i]).transfer(PAYOUT_AMOUNT);
        }
    }

    // Pseudo-random number generator function (unsafe for production use)
    function random(uint mod) private view returns (uint) {
        return
            uint(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, mod))
            ) % mod;
    }

    // Withdraw remaining Ether (for owner only)
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
