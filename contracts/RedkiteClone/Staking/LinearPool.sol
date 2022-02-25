//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract LinearPool is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    uint256 private constant ONE_YEAR_IN_SECONDS = 365 days;

    uint64 public constant LINEAR_MAXIMUM_DELAY_DURATION = 35 days;

    // The accepted token
    IERC20 public linearAcceptedToken;
    // The reward distribution address
    address public linearRewardDistributor;
    // Info of each pools
    LinearPoolInfo[] public linearPoolInfo;
    // Info of each user that stakes in pools
    mapping(uint256 => mapping(address => LinearStakingData))
        public linearStakingData;
    // info pending withdraw of user on each pool
    mapping(uint256 => mapping(address => LinearEmergencyWithdrawal))
        public linearPendingWithdraw;
    // The flexible lock duration. Users who stake in the flexible pool will be affected by this
    uint128 public linearFlexLockDuration;

    bool public linearAllowEmergencyWithdraw;

    event LinearPoolCreated(uint256 indexed poolId, uint256 APR);
    event LinearDeposit(
        uint256 indexed poolId,
        address indexed account,
        uint256 amount
    );

    event LinearWithdraw(
        uint256 indexed poolId,
        address indexed account,
        uint256 amount
    );

    event LinearRewardHarvested(
        uint256 indexed poolId,
        address indexed account,
        uint256 amount
    );

    event LinearPendingWithdraw(
        uint256 indexed poolId,
        address indexed account,
        uint256 amount
    );

    event LinearEmergencyWithdraw(
        uint256 indexed poolId,
        address indexed account,
        uint256 amount
    );

    struct LinearPoolInfo {
        uint128 cap;
        uint128 totalStaked;
        uint128 minInvestment;
        uint128 maxInvestment;
        uint64 APR;
        uint128 lockDuration;
        uint128 delayDuration;
        uint128 startJoinTime;
        uint128 endJoinTime;
    }

    struct LinearStakingData {
        uint128 balance;
        uint128 joinTime;
        uint128 updateTime;
        uint128 reward;
    }

    struct LinearEmergencyWithdrawal {
        uint128 amount;
        uint128 applicableAt;
    }

    /**
     * @notice Initialze the contract, get called in the first time deploy
     * @param _acceptedToken the token that the pools will use as staking and reward token
     */
    function __LinearPool_init(IERC20 _acceptedToken) public {
        __Ownable_init();
        linearAcceptedToken = _acceptedToken;
    }

    /**
     * @notice Validate pool by pool ID
     * @param _poolId id of the pool
     */

    modifier linearValidatePool(uint256 _poolId) {
        require(
            _poolId < linearPoolInfo.length,
            "LinearStakingPool: Pool are not exist"
        );
        _;
    }

    /**
     * @notice return total number of pools
     */
    function linearPoolLength() external view returns (uint256) {
        return linearPoolInfo.length;
    }

    /**
     * @notice return total staked of the pool
     * @param _pooId id of the pool
     */
    function linearTotalStaked(uint256 _poolId)
        external
        view
        linearValidatePool(_poolId)
        returns (uint256)
    {
        return linearPoolInfo[_poolId].totalStaked;
    }

    /**
     * @notice Add a new pool with different APR and conditions. Can only be called by owner
     * @param _cap the maximum number of staking tokens the pool will receive. If this limit is reached. user can not deposit into this pool
     * @param _minInvestment the minimum investment amout each user need to use in order to join the pool
     * @param _maxInvestment the maximum investment amount each user can deposit to join the pool
     * @param _APR the APR rate of the pool
     * @param _lockDuration the duration users need to wait before being able to withdraw and claim rewards
     * @param _delayDuration the duration users need to wait to receive the principal amount, after unstaking from the pool
     * @param _startJoinTime the time when user can start to join the pool
     * @param _endJoinTime the time when user can't to join the pool
     */
    function linearAddPool(
        uint128 _cap,
        uint128 _minInvestment,
        uint128 _maxInvestment,
        uint64 _APR,
        uint128 _lockduration,
        uint128 _delayDuration,
        uint128 _startJoinTime,
        uint128 _endJoinTime
    ) external onlyOwner {
        require(
            _endJoinTime > block.timestamp && _endJoinTime > _startJoinTime,
            "LinearStakingPool: Invalid end join time"
        );
        require(
            _delayDuration <= LINEAR_MAXIMUM_DELAY_DURATION,
            "LinearStakingPool: delay duration is too long"
        );

        linearPoolInfo.push(
            LinearPoolInfo({
                cap: _cap,
                totalStaked: 0,
                minInvestment: _minInvestment,
                maxInvestment: _maxInvestment,
                APR: _APR,
                lockDuration: _lockduration,
                delayDuration: _delayDuration,
                startJoinTime: _startJoinTime,
                endJoinTime: _endJoinTime
            })
        );

        emit LinearPoolCreated(linearPoolInfo.length - 1, _APR);
    }

    /**
     * @notice Update the given pool's info. Can only be called by the owner.
     * @param _poolId id of the pool
     * @param _cap the maximum number of staking tokens the pool will receive. If this limit is reached, users can not deposit into this pool.
     * @param _minInvestment minimum investment users need to use in order to join the pool.
     * @param _maxInvestment the maximum investment amount users can deposit to join the pool.
     * @param _APR the APR rate of the pool.
     * @param _endJoinTime the time when users can no longer join the pool
     */
    function linearSetPool(
        uint128 _poolId,
        uint128 _cap,
        uint128 _minInvestment,
        uint128 _maxIvestment,
        uint64 _APR,
        uint128 _endJoinTime
    ) external linearValidatePool(_poolId) {
        LinearPoolInfo storage pool = linearPoolInfo[_poolId];

        require(
            _endJoinTime > block.timestamp && _endJoinTime > pool.startJoinTime,
            "LinearStakingPool: invalid end join time"
        );

        pool.cap = _cap;
        pool.minInvestment = _minInvestment;
        pool.maxInvestment = _maxIvestment;
        pool.APR = _APR;
        pool.endJoinTime = _endJoinTime;
    }

    /**
     * @notice Set the flexible lock time. This will affects the flexible pool. Can only be called by onwer
     * @param _flexLockDuration the minium lock duration
     */
    function linearSetFlexLockDuration(uint128 _flexLockDuration)
        external
        onlyOwner
    {
        require(
            _flexLockDuration <= LINEAR_MAXIMUM_DELAY_DURATION,
            "LinearStakingPool: flexible lock duration is too long"
        );
        linearFlexLockDuration = _flexLockDuration;
    }

    /**
     * @notice Set the rewarad distributor. Can only be called by the owner
     * @param _linearRewarddistributor the reward distributor
     */
    function linearSetRewardDistributor(address _linearRewardDistributor)
        external
        onlyOwner
    {
        linearRewardDistributor = _linearRewardDistributor;
    }
}
