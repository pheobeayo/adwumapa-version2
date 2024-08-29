// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Adwumapa is Ownable, ReentrancyGuard {
	// Removed IERC20 public usdcToken;

	constructor() Ownable() {}

	event PaymentProcessed(address indexed recipient, uint256 amount);
	event PaymentWithdrawn(address indexed recipient, uint256 amount);
	event EmergencyWithdrawal(address indexed to, uint256 amount);
	event Deposit(address indexed sender, uint256 amount);
	event PaymentReleased(
		address indexed client,
		address indexed freelancer,
		uint256 amount
	);
	event ProjectCompleted(
		address indexed client,
		address indexed freelancer,
		uint256 amount
	);
	event MilestoneCompleted(
		address indexed client,
		address indexed freelancer,
		uint256 milestoneIndex,
		uint256 amount
	);

	mapping(address => uint256) public clientBalances;
	mapping(address => address) public clientFreelancer;
	mapping(address => uint256[]) public clientMilestones; // New mapping for milestones

	// Payment processing functions
	function processPayment(
		address recipient,
		uint256 amount
	) external onlyOwner {
		require(recipient != address(0), "Invalid recipient address");
		require(amount > 0, "Amount must be greater than 0");
		require(
			address(this).balance >= amount,
			"Insufficient contract balance"
		);
		payable(recipient).transfer(amount);
		emit PaymentProcessed(recipient, amount);
	}

	function withdraw(uint256 amount) external onlyOwner {
		require(amount > 0, "Amount must be greater than 0");
		require(
			address(this).balance >= amount,
			"Insufficient contract balance"
		);
		payable(msg.sender).transfer(amount);
		emit PaymentWithdrawn(msg.sender, amount);
	}

	function emergencyWithdraw(address to, uint256 amount) external onlyOwner {
		require(to != address(0), "Invalid recipient address");
		require(amount > 0, "Amount must be greater than 0");
		require(
			address(this).balance >= amount,
			"Insufficient contract balance"
		);
		payable(to).transfer(amount);
		emit EmergencyWithdrawal(to, amount);
	}

	// Function to deposit Ether into the contract
	function deposit(address freelancer) external payable nonReentrant {
		require(msg.value > 0, "Amount must be greater than 0");
		require(freelancer != address(0), "Invalid freelancer address");
		clientBalances[msg.sender] += msg.value;
		clientFreelancer[msg.sender] = freelancer;
		emit Deposit(msg.sender, msg.value);
	}

	// Function to mark project as complete and release payment
	function completeProject() external nonReentrant {
		address freelancer = clientFreelancer[msg.sender];
		uint256 amount = clientBalances[msg.sender];

		require(freelancer != address(0), "No freelancer assigned");
		require(amount > 0, "No funds to release");
		require(
			address(this).balance >= amount,
			"Insufficient contract balance"
		);

		clientBalances[msg.sender] = 0;
		clientFreelancer[msg.sender] = address(0);
		payable(freelancer).transfer(amount);
		emit ProjectCompleted(msg.sender, freelancer, amount);
		emit PaymentReleased(msg.sender, freelancer, amount);
	}

	// Function to release payment when client is satisfied
	function releasePayment(
		address freelancer,
		uint256 amount
	) external nonReentrant {
		require(freelancer != address(0), "Invalid freelancer address");
		require(amount > 0, "Amount must be greater than 0");
		require(
			address(this).balance >= amount,
			"Insufficient contract balance"
		);
		payable(freelancer).transfer(amount);
		emit PaymentReleased(msg.sender, freelancer, amount);
	}

	// Function to mark milestone as complete and release payment
	function completeMilestone(uint256 milestoneIndex) external nonReentrant {
		address freelancer = clientFreelancer[msg.sender];
		uint256 amount = clientMilestones[msg.sender][milestoneIndex];

		require(freelancer != address(0), "No freelancer assigned");
		require(amount > 0, "No funds to release");
		require(
			address(this).balance >= amount,
			"Insufficient contract balance"
		);

		clientMilestones[msg.sender][milestoneIndex] = 0;
		payable(freelancer).transfer(amount);
		emit MilestoneCompleted(msg.sender, freelancer, milestoneIndex, amount);
	}

	// Function to add milestones
	function addMilestone(uint256 amount) external {
		require(amount > 0, "Amount must be greater than 0");
		clientMilestones[msg.sender].push(amount);
	}
}
