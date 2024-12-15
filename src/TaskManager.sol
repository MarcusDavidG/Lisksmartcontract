// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TaskManager {
    struct Task {
        string description;
        uint256 reward;
        uint256 deadline;
        address creator;
        address assignee;
        bool isCompleted;
        bool isPaid;
    }

    mapping(uint256 => Task) public tasks;
    uint256 public taskCount;
    
    event TaskCreated(uint256 taskId, string description, uint256 reward, uint256 deadline);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskCompleted(uint256 taskId);
    event PaymentReleased(uint256 taskId, address to, uint256 amount);

    modifier onlyTaskCreator(uint256 _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Not the task creator");
        _;
    }

    modifier onlyTaskAssignee(uint256 _taskId) {
        require(tasks[_taskId].assignee == msg.sender, "Not the task assignee");
        _;
    }

    function createTask(string memory _description, uint256 _deadline) external payable {
        require(msg.value > 0, "Reward must be greater than 0");
        require(_deadline > block.timestamp, "Deadline must be in the future");

        uint256 taskId = taskCount;
        tasks[taskId] = Task({
            description: _description,
            reward: msg.value,
            deadline: _deadline,
            creator: msg.sender,
            assignee: address(0),
            isCompleted: false,
            isPaid: false
        });

        emit TaskCreated(taskId, _description, msg.value, _deadline);
        taskCount++;
    }

    function takeTask(uint256 _taskId) external {
        require(_taskId < taskCount, "Task does not exist");
        require(tasks[_taskId].assignee == address(0), "Task already taken");
        require(block.timestamp < tasks[_taskId].deadline, "Task deadline passed");
        require(tasks[_taskId].creator != msg.sender, "Creator cannot take their own task");

        tasks[_taskId].assignee = msg.sender;
        emit TaskAssigned(_taskId, msg.sender);
    }

    function completeTask(uint256 _taskId) external onlyTaskAssignee(_taskId) {
        require(!tasks[_taskId].isCompleted, "Task already completed");
        require(block.timestamp <= tasks[_taskId].deadline, "Task deadline passed");

        tasks[_taskId].isCompleted = true;
        emit TaskCompleted(_taskId);
    }

    function releasePayment(uint256 _taskId) external onlyTaskCreator(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.isCompleted, "Task not completed");
        require(!task.isPaid, "Payment already released");
        require(task.assignee != address(0), "Task not assigned");

        task.isPaid = true;
        payable(task.assignee).transfer(task.reward);
        emit PaymentReleased(_taskId, task.assignee, task.reward);
    }

    function getTask(uint256 _taskId) external view returns (
        string memory description,
        uint256 reward,
        uint256 deadline,
        address creator,
        address assignee,
        bool isCompleted,
        bool isPaid
    ) {
        require(_taskId < taskCount, "Task does not exist");
        Task storage task = tasks[_taskId];
        return (
            task.description,
            task.reward,
            task.deadline,
            task.creator,
            task.assignee,
            task.isCompleted,
            task.isPaid
        );
    }
}
