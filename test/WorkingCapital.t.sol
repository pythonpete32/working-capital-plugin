// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import { console2 } from "forge-std/console2.sol";

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { DAO } from "@aragon/osx/core/dao/DAO.sol";
import { DAOMock } from "@aragon/osx/test/dao/DAOMock.sol";
import { IPluginSetup } from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import { DaoUnauthorized } from "@aragon/osx/core/utils/auth.sol";

import { AragonTest } from "./base/AragonTest.sol";

import { WorkingCapitalSetup } from "../src/WorkingCapitalSetup.sol";
import { WorkingCapital } from "../src/WorkingCapital.sol";

abstract contract WorkingCapitalTest is AragonTest {
    DAO internal dao;
    WorkingCapital internal plugin;
    WorkingCapitalSetup internal setup;

    address internal constant HAT_PROTOCOL = 0x3bc1A0Ad72417f2d411118085256fC53CBdDd137;
    uint256 internal constant HAT_ID = 69;
    uint256 internal constant SPENDING_LIMIT = 1000 ether;

    function setUp() public virtual {
        setup = new WorkingCapitalSetup();

        bytes memory SETUP_DATA = abi.encode(HAT_ID, SPENDING_LIMIT);

        (DAO _dao, address _plugin) = createMockDaoWithPlugin(setup, SETUP_DATA);

        dao = _dao;
        plugin = WorkingCapital(_plugin);
    }
}

contract WorkingCapitalInitializeTest is WorkingCapitalTest {
    function setUp() public override {
        super.setUp();
    }

    function test_initialize() public {
        assertEq(address(plugin.dao()), address(dao));
        assertEq(address(plugin.hatsProtocolInstance()), HAT_PROTOCOL);
    }

    function test_reverts_if_reinitialized() public {
        vm.expectRevert("Initializable: contract is already initialized");
        plugin.initialize(dao, HAT_ID, SPENDING_LIMIT);
    }
}

// contract SimpleStorageStoreNumberTest is WorkingCapitalTest {
//     function setUp() public override {
//         super.setUp();
//     }

//     function test_store_number() public {
//         vm.prank(address(dao));
//         plugin.storeNumber(69);
//         assertEq(plugin.number(), 69);
//     }

//     function test_reverts_if_not_auth() public {
//         // error DaoUnauthorized({
//         //     dao: address(_dao),
//         //     where: _where,
//         //     who: _who,
//         //     permissionId: _permissionId
//         // });
//         vm.expectRevert(
//             abi.encodeWithSelector(DaoUnauthorized.selector, dao, plugin, address(this),
// keccak256("STORE_PERMISSION"))
//         );

//         plugin.storeNumber(69);
//     }
// }
