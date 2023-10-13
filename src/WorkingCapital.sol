// SPDX-License-Identifier: MIT
// SPDX-License_Identifier: APGL-3.0-or-later

pragma solidity 0.8.17;

import { PluginCloneable, IDAO } from "@aragon/osx/core/plugin/PluginCloneable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { BokkyPooBahsDateTimeLibrary } from "datetime/BokkyPooBahsDateTimeLibrary.sol";
import { IHats } from "@hats/Interfaces/IHats.sol";

contract WorkingCapital is PluginCloneable {
    bytes32 public constant UPDATE_SPENDING_LIMIT_PERMISSION_ID = keccak256("UPDATE_SPENDING_LIMIT_PERMISSION");

    IHats public hatsProtocolInstance;
    uint256 public hatId;
    uint256 public spendingLimitETH;

    uint256 private currentMonth;
    uint256 private currentYear;
    uint256 private remainingBudget;

    /// @notice Initializes the contract.
    /// @param _dao The associated DAO.
    /// @param _hatId The id of the hat.
    function initialize(IDAO _dao, uint256 _hatId, uint256 _spendingLimitETH) external initializer {
        __PluginCloneable_init(_dao);
        hatId = _hatId;
        // TODO get this from environment per network (this is goerli)
        hatsProtocolInstance = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);
        spendingLimitETH = _spendingLimitETH;
    }

    /// @notice Checking that can user withdraw this amount
    /// @param _actions actions that would be checked
    function hasRemainingBudget(IDAO.Action[] calldata _actions) internal {
        uint256 _currentMonth = BokkyPooBahsDateTimeLibrary.getMonth(block.timestamp);
        uint256 _currentYear = BokkyPooBahsDateTimeLibrary.getYear(block.timestamp);
        uint256 j = 0;
        for (; j < _actions.length; j += 1) {
            //for loop example
            // if we are on the month that we were
            if (_currentMonth == currentMonth && _currentYear == currentYear) {
                require(
                    remainingBudget >= _actions[j].value,
                    string.concat("In ", Strings.toString(j), " action you want to spend more than your limit monthly")
                );
                remainingBudget -= _actions[j].value;
            } else {
                currentYear = _currentYear;
                currentMonth = _currentMonth;
                remainingBudget = spendingLimitETH;
                require(
                    remainingBudget >= _actions[j].value,
                    string.concat("In ", Strings.toString(j), " action you want to spend more than your limit monthly")
                );
                remainingBudget -= _actions[j].value;
            }
        }
    }

    /// @notice Executes actions in the associated DAO.
    /// @param _actions The actions to be executed by the DAO.
    function execute(IDAO.Action[] calldata _actions) external {
        require(hatsProtocolInstance.isWearerOfHat(msg.sender, hatId), "Sender is not wearer of the hat");
        hasRemainingBudget(_actions);
        dao().execute({ _callId: 0x0, _actions: _actions, _allowFailureMap: 0 });
    }

    /// @param _spendingLimitETH The ETH spending limit
    function updateSpendingLimit(uint256 _spendingLimitETH) external auth(UPDATE_SPENDING_LIMIT_PERMISSION_ID) {
        spendingLimitETH = _spendingLimitETH;
    }
}
