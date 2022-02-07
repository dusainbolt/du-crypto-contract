// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDOPool.sol";
import "./IIDOPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract IDOPoolFactory is Ownable, Pausable, Initializable {
    // Array of created Pools Address
    address[] public allPools;
    // Mapping from User CreateToken to Array of created pool token;
    mapping(address => mapping(address => address[])) public getPools;

    event PoolCreated(
        address registeBy,
        address indexed token,
        address indexed pool,
        uint256 poolId
    );

    function initialize() external initializer {
        // Pausable default = false;
        // _unpause();
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Get the number of all created pools
     * @return Return number of created pools
     */
    function getPoolsLength() public view returns (uint256) {
        return allPools.length;
    }

    /**
     * @notice Get the created pool by token and creator
     * @dev User can retrive their created pool by address of token
     * @param _creator Address of created pool User
     * @param _token address of token want to querry
     * @return created pool address
     */
    function getCreatedPoolByToken(address _creator, address _token)
        public
        view
        returns (address[] memory)
    {
        return getPools[_creator][_token];
    }

    /**
     * @notice retrive number of pools created for specific token and creator
     * @dev User can retrive their created pool by address of token
     * @param _creator Address of created pool User
     * @param _token address of token want to querry
     * @return created pool address
     */
    function getCreatePoolByTokenLength(address _creator, address _token)
        public
        view
        returns (uint256)
    {
        return getPools[_creator][_token].length;
    }

    function registerPool(
        address _token,
        uint256 _duration,
        uint256 _openTime,
        address _offeredCurrency,
        uint256 _offeredCurrencyDecimals,
        uint256 _offeredRate,
        address _wallet,
        address _singer
    ) external whenNotPaused returns (address pool) {
        require(_token != address(0), "ICOFactory::ZERO_TOKEN_ADDRESS");
        require(_duration != 0, "ICOFactory::ZERO_DURATION");
        require(_wallet != address(0), "ICOFactory:ZERO_WALLET_ADDRESS");
        require(_offeredRate != 0, "ICOFactory:ZERO_OFFERED_RATE");

        bytes memory bytecode = type(IDOPool).creationCode;
        uint256 tokenIndex = getCreatePoolByTokenLength(msg.sender, _token);
        bytes32 salt = keccak256(
            abi.encodePacked(msg.sender, _token, tokenIndex)
        );
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IIDOPool(pool).initialize(
            _token,
            _duration,
            _openTime,
            _offeredCurrency,
            _offeredRate,
            _offeredCurrencyDecimals,
            _wallet,
            _singer
        );
        getPools[msg.sender][_token].push(pool);
        allPools.push(pool);

        emit PoolCreated(msg.sender, _token, pool, getPoolsLength() - 1);
    }
}
