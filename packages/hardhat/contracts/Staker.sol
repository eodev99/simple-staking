// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

error Staker__StakingNotOpen();

error Staker__NoEthSent();

error Staker__DeadlineNotMet(uint256 timeRemaining);

error Staker__WithdrawalsNotAllowed();

error Staker__CantExecuteAgain();

contract Staker {
    enum StakingState {
        STAKE,
        WITHDWAW,
        SUCCESS
    }

    ExampleExternalContract public exampleExternalContract;

    uint256 public constant threshold = 1 * 10**18;
    uint256 public immutable deadline;
    uint256 private s_lastTimestamp;
    mapping(address => uint256) public balances;
    StakingState private stakingState;

    event Stake(address staker, uint256 amount);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
        stakingState = StakingState.STAKE;
        s_lastTimestamp = block.timestamp;
        deadline = block.timestamp + 259200;
    }

    receive() external payable {
        stake();
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    // deadline counter starts when first amount is deposited
    function stake() public payable {
        //require(block.timestamp < deadline, "Deadline exceeded");
        //-- do we want to be able to stake after deadline but before execute?
        if (stakingState != StakingState.STAKE) {
            revert Staker__StakingNotOpen();
        }
        if (msg.value <= 0) {
            revert Staker__NoEthSent();
        }
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function execute() external {
        if (block.timestamp < deadline) {
            revert Staker__DeadlineNotMet(deadline - block.timestamp);
        }
        if (stakingState != StakingState.STAKE) {
            revert Staker__CantExecuteAgain();
        }
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
            stakingState = StakingState.SUCCESS;
        } else {
            stakingState = StakingState.WITHDWAW;
        }
    }

    function withdraw() external {
        if (stakingState != StakingState.WITHDWAW) {
            revert Staker__WithdrawalsNotAllowed();
        }
        (bool sendSuccess, ) = payable(msg.sender).call{
            value: balances[msg.sender]
        }("");
        balances[msg.sender] = 0;
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return (0);
        }
        return (deadline - block.timestamp);
    }
}
