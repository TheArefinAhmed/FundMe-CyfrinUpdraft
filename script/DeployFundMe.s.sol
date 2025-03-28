// SPDX-License_Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        HelperConfig helperConfig = new HelperConfig(); //it will create a new contract of helperconfig
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig(); //it will get the price feed address
        vm.startBroadcast();
        //Mock
        FundMe fundMe = new FundMe(ethUsdPriceFeed); //when vm.startbroadcst calls it makes the funder msg.sender again
        vm.stopBroadcast();
        return fundMe;
    }
}
