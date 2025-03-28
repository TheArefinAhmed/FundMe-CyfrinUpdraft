// SPDX-License-Identifie: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    uint256 constant GAS_PRICE = 1;
    // address alice = makeAddr("alice");
    uint256 favNumber = 0;
    uint256 public constant SEND_VALUE = 0.1 ether;
    bool greatCourse = false;
    FundMe fundme;
    uint256 constant STARTING_BALANCE = 10 ether;
    address alice = makeAddr("alice");

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundme = deploy.run();
        vm.deal(alice, STARTING_BALANCE);
    }

    function testUserCanFundAndOwnerWithdraw() public {
        uint256 preUserBalance = address(alice).balance;
        uint256 preOwnerBalance = address(fundme.getOwner()).balance;

        // Using vm.prank to simulate funding from the USER address
        vm.prank(alice);
        fundme.fund{value: SEND_VALUE}();

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundme));

        uint256 afterUserBalance = address(alice).balance;
        uint256 afterOwnerBalance = address(fundme.getOwner()).balance;

        assert(address(fundme).balance == 0);
        assertEq(afterUserBalance + SEND_VALUE, preUserBalance);
        assertEq(preOwnerBalance + SEND_VALUE, afterOwnerBalance);
    }
}
