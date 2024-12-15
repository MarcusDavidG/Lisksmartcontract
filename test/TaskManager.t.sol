// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TaskManager.sol";

contract TaskManagerTest is Test {
    TaskManager public taskManager;
    address public creator;
    address public worker;
    uint256 public constant REWARD = 1 ether;

    function setUp() public {
        taskManager = new TaskManager();
        creator = makeAddr("creator");
        worker = makeAddr("worker");
        vm.deal(creator, 10 ether);
    }

    function testCreateTask() public {
        vm.startPrank(creator);
        uint256 deadline = block.timestamp + 1 days;
        taskManager.createTask{value: REWARD}("Test task", deadline);
        vm.stopPrank();

        (
            string memory description,
            uint256 reward,
            uint256 taskDeadline,
            address taskCreator,
            address assignee,
            bool isCompleted,
            bool isPaid
        ) = taskManager.getTask(0);

        assertEq(description, "Test task");
        assertEq(reward, REWARD);
        assertEq(taskDeadline, deadline);
        assertEq(taskCreator, creator);
        assertEq(assignee, address(0));
        assertEq(isCompleted, false);
        assertEq(isPaid, false);
    }

    function testTakeTask() public {
        // First create a task
        vm.startPrank(creator);
        uint256 deadline = block.timestamp + 1 days;
        taskManager.createTask{value: REWARD}("Test task", deadline);
        vm.stopPrank();

        // Worker takes the task
        vm.startPrank(worker);
        taskManager.takeTask(0);
        vm.stopPrank();

        (, , , , address assignee, , ) = taskManager.getTask(0);
        assertEq(assignee, worker);
    }

    function testCompleteTaskAndPayment() public {
        // Create task
        vm.startPrank(creator);
        uint256 deadline = block.timestamp + 1 days;
        taskManager.createTask{value: REWARD}("Test task", deadline);
        vm.stopPrank();

        // Take task
        vm.startPrank(worker);
        taskManager.takeTask(0);
        
        // Complete task
        taskManager.completeTask(0);
        vm.stopPrank();

        // Verify task completion
        (, , , , , bool isCompleted, ) = taskManager.getTask(0);
        assertEq(isCompleted, true);

        // Release payment
        uint256 workerInitialBalance = worker.balance;
        vm.startPrank(creator);
        taskManager.releasePayment(0);
        vm.stopPrank();

        // Verify payment
        (, , , , , , bool isPaid) = taskManager.getTask(0);
        assertEq(isPaid, true);
        assertEq(worker.balance, workerInitialBalance + REWARD);
    }

    function testFailTaskDeadline() public {
        // Create task
        vm.startPrank(creator);
        uint256 deadline = block.timestamp + 1 days;
        taskManager.createTask{value: REWARD}("Test task", deadline);
        vm.stopPrank();

        // Take task
        vm.startPrank(worker);
        taskManager.takeTask(0);
        
        // Warp time past deadline
        vm.warp(block.timestamp + 2 days);
        
        // Try to complete task after deadline (should fail)
        taskManager.completeTask(0);
        vm.stopPrank();
    }
}
