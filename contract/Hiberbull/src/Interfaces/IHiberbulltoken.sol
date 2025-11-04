// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHiberbullToken {
  /// @notice Transfers tokens to a specified address
   function transfer(address to, uint256 amount) external returns (bool);
   /// @notice Transfers tokens from one address to another
   function transferFrom(address from,address to,uint256 amount) external returns (bool);
   /// @notice Returns the token balance of a specified address
   function balanceOf(address account) external view returns (uint256);
   /// @notice Returns the total supply of tokens
   function totalSupply() external view returns (uint256);
   /// @notice Allows a spender to withdraw from the owner's account multiple times, up to the amount specified
   function approve(address spender, uint256 amount) external returns (bool);

   /// @notice Returns the remaining number of tokens that a spender is allowed to withdraw from the owner's account
   function allowance(address owner, address spender) external view returns (uint256);

}
