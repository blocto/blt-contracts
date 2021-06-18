// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Token.sol";

contract TeleportCustody is AccessControl {
    using SafeMath for uint256;
    bytes32 public constant TELEPORT_ADMIN_ROLE =
        keccak256("TELEPORT_ADMIN_ROLE");

    mapping(address => uint256) private _allowedAmount;

    bool private _isFrozen;
    Token private _token;

    event AdminUpdated(address indexed account, uint256 allowedAmount);

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

    /**
     * @dev Updates the admin status of an account.
     * Can only be called by the current owner.
     */
    function depositAllowance(address account, uint256 allowedAmount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _allowedAmount[account] = _allowedAmount[account].add(allowedAmount);
        emit AdminUpdated(account, allowedAmount);
    }

    /**
     * @dev Checks the authorized amount of an admin account.
     */
    function allowedAmount(address account) public view returns (uint256) {
        return _allowedAmount[account];
    }
}
