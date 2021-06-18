// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Token.sol";

contract TeleportCustody is AccessControl {
    bool private _isFrozen;
    Token private _token;

    constructor(Token token) {
        _token = token;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Throw if contract is currently frozen.
     */
    modifier notFrozen() {
        require(!_isFrozen, "contract is frozen by owner");

        _;
    }

    /**
     * @dev Returns if the contract is currently frozen.
     */
    function isFrozen() public view returns (bool) {
        return _isFrozen;
    }

    /**
     * @dev Owner freezes the contract.
     */
    function freeze() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _isFrozen = true;
    }

    /**
     * @dev Owner unfreezes the contract.
     */
    function unfreeze() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _isFrozen = false;
    }

    /**
     * @dev Returns the teleport token
     */
    function getToken() public view returns (Token) {
        return _token;
    }
}
