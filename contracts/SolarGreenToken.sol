// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SolarGreenToken is ERC20, AccessControl {
    address payable public owner;
    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTED_ROLE");
    bytes32 public constant IN_BLACKLIST_ROLE = keccak256("IN_BLACKLIST_ROLE");

    mapping(address => bool) private in_blacklist_role;

    event AddressAddedToBlacklist(address indexed account);
    event AddressRemovedFromBlacklist(address indexed account);

    constructor(address shop) ERC20("SolarGreen", "SGT") {
        owner = payable(msg.sender);
        _mint(shop, 100000000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    // Minting additional tokens.
    function mint(
        address to,
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount * 10 ** decimals());
    }

    // Burn tokens.
    function burn(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(owner, amount);
    }

    // Assignment of the BLACKLISTER_ROLE.
    function blacklisterRoleAssign(
        address user
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!hasRole(BLACKLISTER_ROLE, user), "User is a blacklister!");
        _grantRole(BLACKLISTER_ROLE, user);
    }

    // Revocation of the BLACKLISTER_ROLE.
    function blacklistedRoleRevoke(
        address user
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(BLACKLISTER_ROLE, user), "User is NOT a blacklister!");
        _revokeRole(BLACKLISTER_ROLE, user);
    }

    // Check if the user has the BLACKLISTER_ROLE.
    function isRoleUserBlacklister(address user) public view returns (bool) {
        return hasRole(BLACKLISTER_ROLE, user);
    }

    // Add to the BLACK LIST
    function addToBlacklist(address user) public {
        require(
            hasRole(BLACKLISTER_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a BLACKLISTER or ADMIN"
        );
        require(
            !hasRole(IN_BLACKLIST_ROLE, user),
            "User is already in the blacklist!"
        );
        in_blacklist_role[user] = true;
        _grantRole(IN_BLACKLIST_ROLE, user);
        emit AddressAddedToBlacklist(user);
    }

    // Remove from the BLACK LIST
    function removeFromBlacklist(address user) public {
        require(
            hasRole(BLACKLISTER_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a BLACKLISTER or ADMIN"
        );
        require(
            hasRole(IN_BLACKLIST_ROLE, user),
            "User is NOT in the blacklist!"
        );
        in_blacklist_role[user] = false;
        _revokeRole(IN_BLACKLIST_ROLE, user);
        emit AddressRemovedFromBlacklist(user);
    }

    // Check if the user is in the black list
    function isUserInBlacklist(address user) public view returns (bool) {
        return in_blacklist_role[user];
    }
}
