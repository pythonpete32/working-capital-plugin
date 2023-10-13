// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import { console2 } from "forge-std/console2.sol";

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { DAO } from "@aragon/osx/core/dao/DAO.sol";
import { DAOMock } from "@aragon/osx/test/dao/DAOMock.sol";
import { IPluginSetup } from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import { DaoUnauthorized } from "@aragon/osx/core/utils/auth.sol";
import { PluginRepo } from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";

import { AragonE2E } from "./base/AragonE2E.sol";
import { WorkingCapitalSetup } from "../src/WorkingCapitalSetup.sol";
import { WorkingCapital } from "../src/WorkingCapital.sol";

contract WorkingCapitalE2E is AragonE2E {
    address internal unauthorised = account("unauthorised");
    DAO internal dao;

    WorkingCapital internal plugin;
    PluginRepo internal repo;
    WorkingCapitalSetup internal setup;

    address internal constant HAT_PROTOCOL = 0x3bc1A0Ad72417f2d411118085256fC53CBdDd137;
    uint256 internal constant HAT_ID = 69;
    uint256 internal constant SPENDING_LIMIT = 1000 ether;

    function setUp() public virtual override {
        super.setUp();
    }

    function test_e2e() public {
        setup = new WorkingCapitalSetup();
        address _plugin;

        bytes memory SETUP_DATA = abi.encode(HAT_ID, SPENDING_LIMIT);

        (dao, repo, _plugin) = deployRepoAndDao("workingcapital420", address(setup), SETUP_DATA);

        plugin = WorkingCapital(_plugin);

        // test repo
        PluginRepo.Version memory version = repo.getLatestVersion(repo.latestRelease());
        assertEq(version.pluginSetup, address(setup));
        assertEq(version.buildMetadata, NON_EMPTY_BYTES);

        // test dao
        assertEq(keccak256(bytes(dao.daoURI())), keccak256(bytes("https://mockDaoURL.com")));
    }
}
