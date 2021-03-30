pragma solidity ^0.5.17;

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import './MochiToken.sol';

contract MochiChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of MOCHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accMochiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accMochiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. MOCHIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that MOCHIs distribution occurs.
        uint256 accMochiPerShare; // Accumulated MOCHIs per share, times 1e12. See below.
    }
    // The mochi TOKEN!
    MochiToken public mochi;
    // Dev address.
    address public devaddr;

    // Block number when bonus mochi period ends.
    uint256 public bonusEndBlock_a;
    uint256 public bonusEndBlock_b;
    uint256 public bonusEndBlock_c;
    uint256 public bonusEndBlock_d;
    uint256 public bonusEndBlock_e;
    uint256 public bonusEndBlock_f;
    uint256 public bonusEndBlock_g;
    uint256 public bonusEndBlock_h;
    uint256 public bonusEndBlock_i;
    uint256 public bonusEndBlock_j;
    uint256 public bonusEndBlock_k;
    uint256 public bonusEndBlock;

    // mochi tokens created per block.
    uint256 public mochiPerBlock;
    // Bonus muliplier for early mochi makers.
    uint256 public constant BONUS_MULTIPLIER_A = 25;
    uint256 public constant BONUS_MULTIPLIER_B = 20;
    uint256 public constant BONUS_MULTIPLIER_C = 15;
    uint256 public constant BONUS_MULTIPLIER_D = 12;
    uint256 public constant BONUS_MULTIPLIER_E = 10;
    uint256 public constant BONUS_MULTIPLIER_F = 8;
    uint256 public constant BONUS_MULTIPLIER_G = 6;
    uint256 public constant BONUS_MULTIPLIER_H = 5;
    uint256 public constant BONUS_MULTIPLIER_I = 4;
    uint256 public constant BONUS_MULTIPLIER_J = 3;
    uint256 public constant BONUS_MULTIPLIER_K = 2;
    uint256 public constant BONUS_MULTIPLIER_OFF = 1;

    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    // IMigratorChef public migrator; // Migrator REMOVED

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when mochi mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor (
        MochiToken _mochi,
        address _devaddr,
        uint256 _mochiPerBlock,
        uint256 _startBlock,
        uint256 _blocksPerPeriod // 1 day
    ) public {
        mochi = _mochi;
        devaddr = _devaddr;
        mochiPerBlock = _mochiPerBlock;
        startBlock = _startBlock;
        bonusEndBlock_a = _startBlock + _blocksPerPeriod.mul(7); // 25
        bonusEndBlock_b = bonusEndBlock_a + _blocksPerPeriod.mul(7); // 20
        bonusEndBlock_c = bonusEndBlock_b + _blocksPerPeriod.mul(7); // 15
        bonusEndBlock_d = bonusEndBlock_c + _blocksPerPeriod.mul(7); // 12
        bonusEndBlock_e = bonusEndBlock_d + _blocksPerPeriod.mul(7); // 10
        bonusEndBlock_f = bonusEndBlock_e + _blocksPerPeriod.mul(7); // 8
        bonusEndBlock_g = bonusEndBlock_f + _blocksPerPeriod.mul(7); // 6
        bonusEndBlock_h = bonusEndBlock_g + _blocksPerPeriod.mul(14); // 5
        bonusEndBlock_i = bonusEndBlock_h + _blocksPerPeriod.mul(14); // 4
        bonusEndBlock_j = bonusEndBlock_i + _blocksPerPeriod.mul(14); // 3
        bonusEndBlock_k = bonusEndBlock_j + _blocksPerPeriod.mul(14); // 2
        bonusEndBlock = bonusEndBlock_k + _blocksPerPeriod.mul(14); // 1
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accMochiPerShare: 0
            })
        );
    }

    // Update the given pool's mochi allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function getMultiplierBonus(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if ((_from >= startBlock) && (_to < bonusEndBlock_a)) {
            return BONUS_MULTIPLIER_A;
        } else if ((_from >= bonusEndBlock_a) && (_to < bonusEndBlock_b)) {
            return BONUS_MULTIPLIER_B;
        } else if ((_from >= bonusEndBlock_b) && (_to < bonusEndBlock_c)) {
            return BONUS_MULTIPLIER_C;
        } else if ((_from >= bonusEndBlock_c) && (_to < bonusEndBlock_d)) {
            return BONUS_MULTIPLIER_D;
        } else if ((_from >= bonusEndBlock_d) && (_to < bonusEndBlock_e)) {
            return BONUS_MULTIPLIER_E;
        } else if ((_from >= bonusEndBlock_e) && (_to < bonusEndBlock_f)) {
            return BONUS_MULTIPLIER_F;
        } else if ((_from >= bonusEndBlock_f) && (_to < bonusEndBlock_g)) {
            return BONUS_MULTIPLIER_G;
        } else if ((_from >= bonusEndBlock_g) && (_to < bonusEndBlock_h)) {
            return BONUS_MULTIPLIER_H;
        } else if ((_from >= bonusEndBlock_h) && (_to < bonusEndBlock_i)) {
            return BONUS_MULTIPLIER_I;
        } else if ((_from >= bonusEndBlock_i) && (_to < bonusEndBlock_j)) {
            return BONUS_MULTIPLIER_J;
        } else if ((_from >= bonusEndBlock_j) && (_to < bonusEndBlock_k)) {
            return BONUS_MULTIPLIER_K;
        } else {
            return BONUS_MULTIPLIER_OFF;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        uint256 _mult = getMultiplierBonus(_from, _to);
        // if end block is smaller than/before bonus end block
        if (_to <= bonusEndBlock) {
            // add bonus by getting number of blocks in range
            return _to.sub(_from).mul(_mult);
            // if start block is after end return normal reward
        } else if (_from >= bonusEndBlock) {
            // no bonus
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(_mult).add(_to.sub(bonusEndBlock));
        }
    }

    // View function to see pending MOCHIs on frontend.
    function pendingMochi(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMochiPerShare = pool.accMochiPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 mochiReward =
                multiplier.mul(mochiPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accMochiPerShare = accMochiPerShare.add(
                mochiReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accMochiPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update p vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 mochiReward =
            multiplier.mul(mochiPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        mochi.mint(devaddr, mochiReward.div(10));
        mochi.mint(address(this), mochiReward);
        pool.accMochiPerShare = pool.accMochiPerShare.add(
            mochiReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MochiChef for mochi allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accMochiPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeMochiTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accMochiPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MochiChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accMochiPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeMochiTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accMochiPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe mochi transfer function, just in case if rounding error causes pool to not have enough MOCHIs.
    function safeMochiTransfer(address _to, uint256 _amount) internal {
        uint256 mochiBal = mochi.balanceOf(address(this));
        if (_amount > mochiBal) {
            mochi.transfer(_to, mochiBal);
        } else {
            mochi.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}
