// SPDX-License-Identifie: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {FoundryZkSyncChecker} from "lib/foundry-devops/src/FoundryZkSyncChecker.sol";

contract FundMeTest is Test {
    uint256 constant GAS_PRICE = 1;
    address alice = makeAddr("alice");
    uint256 favNumber = 0;
    uint256 public constant SEND_VALUE = 0.1 ether;
    bool greatCourse = false;
    FundMe fundme;
    uint256 constant STARTING_BALANCE = 10 ether;

    modifier funded() {
        vm.prank(alice);
        vm.deal(alice, STARTING_BALANCE);
        fundme.fund{value: SEND_VALUE}();
        assert(address(fundme).balance > 0);
        _;
    }

    function setUp() external {
        // favNumber = 1337;
        // greatCourse = true;
        // console.log("This will get printed at first.");
        // fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
    }

    // function testDemo() public {
    //     assertEq(favNumber, 1337);
    //     assertEq(greatCourse, true);
    //     console.log("This will get printed second!");
    //     console.log("Updraft is changing lives!");
    //     console.log(
    //         "You can print multiple things, for example this is a uint256, followed by a bool:",
    //         favNumber,
    //         greatCourse
    //     );
    // }

    function testMinimumDollarIsFive() public {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        // console.log(fundme.i_owner());
        // console.log(msg.sender); // it is whoever is calling the fundme test
        // assertEq(fundme.i_owner(), msg.sender);
        assertEq(fundme.i_owner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundme.getVersion();
        assertEq(version, 4);
    }

    // function testFailsWithoutEnoughEth() public {
    //     vm.expectRevert();
    //     fundme.fund();
    // }

    // !!!!!!! testFailsWithoutEnoughEth here testFail keyword is not allowed so we are using testFailsWithoutEnoughEth below

    function test_RevertWhen_NotEnoughEthSent() public {
        vm.expectRevert();
        fundme.fund();
    }

    // function testFundUpdatesFundDataStructure() public {
    //     vm.deal(alice, STARTING_BALANCE);
    //     vm.prank(alice);
    //     fundme.fund{value: SEND_VALUE}();
    //     uint256 amountFunded = fundme.getAddressToAmountFunded(alice);
    //     assertEq(amountFunded, SEND_VALUE);
    // }
    function testFundUpdatesFundDataStructure() public {
        vm.prank(alice);
        vm.deal(alice, STARTING_BALANCE);
        fundme.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundme.getAddressToAmountFunded(alice);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.startPrank(alice);
        vm.deal(alice, STARTING_BALANCE);
        fundme.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = fundme.getFunder(0);
        assertEq(funder, alice);
    }

    // function testOnlyOwnerCanWithdraw() public {
    //     vm.prank(alice);
    //     vm.deal(alice, STARTING_BALANCE);

    //     fundme.fund{value: SEND_VALUE}();

    //     vm.expectRevert();
    //     vm.prank(alice);
    //     fundme.withdraw();
    // }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundme.withdraw();
    }

    function testWithdrawFromASingleFunder() public funded {
        uint256 startingFundMeBalance = address(fundme).balance; //initial balance of the contract
        uint256 startingOwnerBalance = fundme.getOwner().balance; //initial balance of the owner

        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();

        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Withdraw consumed: %d gas", gasUsed);

        uint256 endingFundMeBalance = address(fundme).balance;
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingFundBalance = address(fundme).balance;
        uint256 startingOwnerBalance = fundme.getOwner().balance;

        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();

        assert(address(fundme).balance == 0);
        assert(
            startingFundBalance + startingOwnerBalance ==
                fundme.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundme.getOwner().balance - startingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingFundBalance = address(fundme).balance;
        uint256 startingOwnerBalance = fundme.getOwner().balance;

        vm.startPrank(fundme.getOwner());
        fundme.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundme).balance == 0);
        assert(
            startingFundBalance + startingOwnerBalance ==
                fundme.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundme.getOwner().balance - startingOwnerBalance
        );
    }
}
