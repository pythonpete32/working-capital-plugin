// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { console2 } from "forge-std/console2.sol";

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { PermissionLib } from "@aragon/osx/core/permission/PermissionLib.sol";
import { PluginSetup, IPluginSetup } from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import { WorkingCapital } from "./WorkingCapital.sol";
import { IDAO } from "@aragon/osx/core/plugin/Plugin.sol";
import { DAO } from "@aragon/osx/core/dao/DAO.sol";

contract WorkingCapitalSetup is PluginSetup {
    using Clones for address;

    /// @notice The address of `WorkingCapital` plugin logic contract to be cloned.
    address private immutable workingCapitalImplementation;

    /// @notice The constructor setting the `Admin` implementation contract to clone from.
    constructor() {
        workingCapitalImplementation = address(new WorkingCapital());
    }

    /// @inheritdoc IPluginSetup
    function prepareInstallation(
        address _dao,
        bytes calldata _data
    )
        external
        returns (address plugin, PreparedSetupData memory preparedSetupData)
    {
        console2.log("before decode");
        // Decode `_data` to extract the params needed for cloning and initializing the `Admin` plugin.
        (uint256 hatId, uint256 spendingLimitETH) = abi.decode(_data, (uint256, uint256));
        console2.log("after decode");

        console2.log("before clone");

        // Clone plugin contract.
        plugin = workingCapitalImplementation.clone();

        console2.log("after clone");

        // Initialize cloned plugin contract.
        WorkingCapital(plugin).initialize(IDAO(_dao), hatId, spendingLimitETH);

        // Prepare permissions
        PermissionLib.MultiTargetPermission[] memory permissions = new PermissionLib.MultiTargetPermission[](2);

        // Grant the `EXECUTE_PERMISSION` on the DAO to the plugin.
        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: _dao,
            who: plugin,
            condition: PermissionLib.NO_CONDITION,
            permissionId: DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        });

        permissions[1] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: WorkingCapital(plugin).UPDATE_SPENDING_LIMIT_PERMISSION_ID()
        });

        preparedSetupData.permissions = permissions;
    }

    /// @inheritdoc IPluginSetup
    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    )
        external
        view
        returns (PermissionLib.MultiTargetPermission[] memory permissions)
    {
        // Collect addresses
        address plugin = _payload.plugin;

        // Prepare permissions
        permissions = new PermissionLib.MultiTargetPermission[](2);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _dao,
            who: plugin,
            condition: PermissionLib.NO_CONDITION,
            permissionId: DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        });

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: WorkingCapital(plugin).UPDATE_SPENDING_LIMIT_PERMISSION_ID()
        });
    }

    /// @inheritdoc IPluginSetup
    function implementation() external view returns (address) {
        return workingCapitalImplementation;
    }
}
