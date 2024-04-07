// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "./SolarGreenToken.sol";
import "./TokenBlockedForTime.sol";

contract TokenSale is AccessControl {
    using SafeERC20 for IERC20;

    IERC20 private token;
    uint256 private saleStartDate;
    uint256 private saleDuration;
    uint256 private constant maxTokensPerUser = 50000 * 10 ** 18;
    uint256 private constant vestingEndDate = 1735682399;
    TokenBlockedForTime private tokenTimelock;
    uint256 private tokenPriceInUSDT;
    address payable public owner;
    uint256 public tokensSold;
    address public constant addressUSDT =
        0x1531BC5dE10618c511349f8007C08966E45Ce8ef;
    address public constant addressETH =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    AggregatorV3Interface internal priceFeed;
    SolarGreenToken private sgrInstance;

    mapping(address => uint256) private tokensPurchased;

    event Sell(address indexed buyer, uint256 amount, uint256 price);

    constructor(uint256 _tokenPriceInUSDT) {
        require(_tokenPriceInUSDT > 0, "Token price must be greater than 0");
        tokenPriceInUSDT = _tokenPriceInUSDT;
        token = new SolarGreenToken(address(this));
        tokenTimelock = new TokenBlockedForTime(token);
        priceFeed = AggregatorV3Interface(addressETH);
        owner = payable(msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        sgrInstance = SolarGreenToken(address(this));
        saleStartDate = 1710712801;
        saleDuration = 5 weeks;
    }

    function setSaleDuration(
        uint256 _startSaleUnix,
        uint256 _saleDuration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        saleStartDate = _startSaleUnix;
        saleDuration = _saleDuration;
    }

    // Checking whether 50 percent of the tokens have been sold
    function checkHalfSold() public view returns (bool) {
        return tokensSold >= token.totalSupply() / 2;
    }

    // Function for setting the token price in USDT
    function setTokenPriceInUSDT(
        uint256 _tokenPriceInUSDT
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokenPriceInUSDT > 0, "Token price must be greater than 0");
        tokenPriceInUSDT = _tokenPriceInUSDT;
    }

    // Function for getting the token price in USDT
    function getTokenPriceInUSDT() public view returns (uint256) {
        return tokenPriceInUSDT * 10 ** 18;
    }

    // Function for getting the token price in ETH
    function getTokenPriceInETH() public view returns (uint256) {
        (, int256 priceETH, , , ) = priceFeed.latestRoundData();

        return uint(priceETH * 1e10);
    }

    // Function convertable
    function getConversionRate(uint256 _amount) public view returns (uint256) {
        uint rate = (_amount * 1e18) / getTokenPriceInETH();
        return rate;
    }

    // Function get balance of USDT
    function usdtBalanceOf(address user) public view returns (uint256) {
        return IERC20(addressUSDT).balanceOf(user);
    }

    // Function get balance of ETH
    function ethBalanceOf(address user) public view returns (uint256) {
        return address(user).balance;
    }

    // Function for buying tokens for USDT
    function buyTokensForUSDT(uint256 _amount) external {
        address payable buyer = payable(msg.sender);
        uint256 amountToSell = _amount * 10 ** 18;
        uint256 amountUsdtForPurchase = amountToSell / getTokenPriceInUSDT();
        require(
            sgrInstance.isUserInBlacklist(buyer),
            "User is in the blacklist"
        );
        require(!checkHalfSold(), "Sell is stopped, sold 50% of tokens");
        require(
            block.timestamp < saleStartDate &&
                block.timestamp > saleStartDate + saleDuration,
            "Sale is not active"
        );
        require(
            tokensPurchased[buyer] + amountToSell <= maxTokensPerUser,
            "The maximum number of tokens per user has been exceeded"
        );
        require(
            amountUsdtForPurchase > 0,
            "Amount of USDT for purchase must be greater than zero"
        );
        require(
            IERC20(addressUSDT).balanceOf(buyer) >= amountUsdtForPurchase,
            "Insufficient USDT balance"
        );
        require(
            IERC20(addressUSDT).allowance(buyer, address(this)) >=
                amountUsdtForPurchase,
            "Insufficient USDT allowance"
        );

        // Transfer USDT to the owner
        IERC20(addressUSDT).transferFrom(
            buyer,
            address(this),
            amountUsdtForPurchase
        );
        // Transfer tokens to the contract for temporary blocking
        tokenTimelock.createTimelock(buyer, amountToSell);

        // Recording the number of purchased tokens per user
        tokensPurchased[buyer] += amountToSell;

        emit Sell(buyer, amountToSell, getTokenPriceInUSDT());
    }

    function buyTokensForETH(uint256 _amount) external {
        address payable buyer = payable(msg.sender);
        uint256 amountToSell = _amount * 10 ** 18;
        uint256 amountUsdtForPurchase = amountToSell / getTokenPriceInUSDT();
        uint256 amountEhtForPurchase = getConversionRate(amountUsdtForPurchase);
        require(
            sgrInstance.isUserInBlacklist(buyer),
            "User is in the blacklist"
        );
        require(!checkHalfSold(), "Sell is stopped, sold 50% of tokens");
        require(
            block.timestamp < saleStartDate &&
                block.timestamp > saleStartDate + saleDuration,
            "Sale is not active"
        );
        require(
            tokensPurchased[buyer] + amountToSell <= maxTokensPerUser,
            "The maximum number of tokens per user has been exceeded"
        );
        require(
            ethBalanceOf(buyer) >= amountEhtForPurchase,
            "Insufficient ETH"
        );

        require(
            token.balanceOf(address(this)) >= amountToSell,
            "Insufficient tokens in the sales contract"
        );
        require(
            token.allowance(buyer, address(this)) >= amountEhtForPurchase,
            "Insufficient ETH allowance"
        );
        // Transfer ETH to the owner
        token.transferFrom(buyer, address(this), amountEhtForPurchase);

        // Transfer tokens to the contract for temporary blocking
        tokenTimelock.createTimelock(buyer, amountToSell);

        // Recording the number of purchased tokens per user
        tokensPurchased[buyer] += amountToSell;

        emit Sell(msg.sender, amountToSell, amountEhtForPurchase);
    }

    // Function for getting the number of tokens blocked for the user
    function getTokensBlockedForUser(
        address user
    ) public view returns (TokenBlockedForTime.Timelock[] memory) {
        return tokenTimelock.getTimelocks(user);
    }

    // Function for withdrawing USDT
    function withdrawUSDT() external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(addressUSDT).transfer(
            owner,
            IERC20(addressUSDT).balanceOf(address(this))
        );
    }

    // Function for withdrawing ETH
    function withdrawETH() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(owner).transfer(address(this).balance);
    }
}
