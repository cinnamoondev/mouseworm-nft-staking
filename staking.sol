// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MouseWormStaking is Ownable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;

    //store data of each user in UserInfo
    struct UserInfo {
        uint112 nftBoost; //NFT token multiplier
        uint32 lockedUntil; //lock end in UNIX seconds, used to compute the lockTimeBoost
        uint32 lockTimeBoost;
        uint96 claimableETH; //amount of eth ready to be claimed
        uint112 weightedBalance; //amout of staked tokens * multiplier * nftMultiplier
        uint256 withdrawn; //sum of withdrawn ETH
        uint112 ETHrewardDebt; //ETH debt for each staking session. Session resets upon withdrawal
        address[] NFTContracts; //array of nft contracts (for multiple NFTcontract boost
        uint256[] NFTTokenIDs; //nft id tracker
    }
    // store data of each pool
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint64 allocPoint; // How many allocation points assigned to this pool.
        uint64 lastRewardBlock; // Last reward block.
        uint112 accETHPerShare; // Accumulated ETH rewards
        uint112 weightedBalance; // weightedBalances from all users.
    }

    // helper to track users NFTs
    struct UsersNFTs {
        address NFTContract; // address
        uint256 TokenId; // id of token (NFT)
    }

    uint112 public pointsPerNFT = 1000000000000000; //amount of bonus points that each NFT gives to staker
    uint256 constant ONE_DAY = 86400; //total seconds in one day
    address public WETH; // The WETH token contract
    mapping(address => bool) public isNFTContract; // check if address is NFT contract
    uint256 public ETHPerBlock; // amount of ETH per block
    uint256 public ETHLeftUnshared; // amount of ETH that is not distributed to stakers
    uint256 public ETHLeftUnclaimed; // amount of ETH that is distributed but unclaimed
    uint256 public numdays; // number of days used to calculate rewards. Feed the staking contract with ETH within numdays days
    address public TaxDistributor; // address of taxDistributor. Just in case TD transfers the ETH without arbitrary data

    PoolInfo[] public poolInfo; // pool info storage
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // userinfo storage

    uint256 public totalAllocPoint; // total allocation points
    uint256 public startBlock; // starting block
    bool public isEmergency; //if Emergency users can withdraw their tokens without caring about the locks and rewards

    //events
    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 lockTime
    );
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event NFTStaked(
        address indexed user,
        address indexed NFTContract,
        uint256 tokenID
    );
    event NFTWithdrawn(
        address indexed user,
        address indexed NFTContract,
        uint256 tokenID
    );
    event TokensLocked(
        address indexed user,
        uint256 timestamp,
        uint256 lockTime
    );
    event Emergency(uint256 timestamp, bool ifEmergency);

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(
            poolExistence[_lpToken] == false,
            "nonDuplicated: LP Token already added"
        );
        _;
    }

    modifier onlyEmergency() {
        require(isEmergency == true, "onlyEmergency: Emergency use only!");
        _;
    }
    mapping(address => bool) public authorized;
    modifier onlyAuthorized() {
        require(
            authorized[msg.sender] == true,
            "onlyAuthorized: address not authorized"
        );
        _;
    }

    constructor() {
        startBlock = type(uint256).max;
        numdays = 13;
    }

    /**
     * poolLength
     * Returns total number of pools
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * getMultiplier
     * Return reward multiplier over the given _from to _to block.
     */
    function getMultiplier(uint256 _from, uint256 _to)
    public
    pure
    returns (uint256)
    {
        return (_to - _from);
    }

    /**
     * pendingRewards
     * Calculate pending rewards
     */
    function pendingRewards(uint256 _pid, address _user)
    external
    view
    returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 userWeightedAmount = user.weightedBalance;
        uint256 accETHPerShare = pool.accETHPerShare;
        uint256 weightedBalance = pool.weightedBalance;
        uint256 PendingETH;
        if (block.number > pool.lastRewardBlock && weightedBalance != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 ETHReward = (multiplier * ETHPerBlock * pool.allocPoint) /
            totalAllocPoint;
            accETHPerShare =
            accETHPerShare +
            (ETHReward * 1e12) /
            weightedBalance;
            PendingETH =
            ((userWeightedAmount * accETHPerShare) / 1e12) -
            user.ETHrewardDebt +
            user.claimableETH;
        }
        return (PendingETH);
    }

    /**
     * getUsersNFTs
     * Return array of contracts and ids of users staked NFTs
     */
    function getUsersNFTs(uint256 _pid, address _user)
    public
    view
    returns (address[] memory, uint256[] memory)
    {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 nftCount = user.NFTContracts.length;

        address[] memory _nftContracts = new address[](nftCount);
        uint256[] memory _nftTokenIds = new uint256[](nftCount);

        for (uint256 i = 0; i < nftCount; i++) {
            _nftContracts[i] = user.NFTContracts[i];
            _nftTokenIds[i] = user.NFTTokenIDs[i];
        }

        return (_nftContracts, _nftTokenIds);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    //Receive ETH from the tax splitter contract. triggered on a value transfer with .call("arbitraryData").
    fallback() external payable {
        ETHLeftUnshared += msg.value;
        updateETHRewards();
    }

    receive() external payable {
        require(msg.sender != TaxDistributor);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.weightedBalance;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = uint64(block.number);
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        uint256 ETHReward = (multiplier * ETHPerBlock * pool.allocPoint) /
        totalAllocPoint;

        ETHLeftUnclaimed = ETHLeftUnclaimed + ETHReward;
        ETHLeftUnshared = ETHLeftUnshared - ETHReward;
        pool.accETHPerShare = uint112(
            pool.accETHPerShare + (ETHReward * 1e12) / lpSupply
        );
        pool.lastRewardBlock = uint64(block.number);
    }


    // Withdraw previously staked NFT, loosing the rewards boost
    function withdrawNFT(
        uint256 _pid,
        address NFTContract,
        uint256 tokenID
    ) public nonReentrant {
        address sender = msg.sender;
        uint256 NFTIndex;
        bool tokenFound;
        uint256 length = userInfo[_pid][sender].NFTContracts.length;
        require(userInfo[_pid][sender].lockedUntil < block.timestamp, "withdraw: still locked");
        updatePool(_pid);
        _addToClaimable(_pid, sender);
        for (uint256 i; i < userInfo[_pid][sender].NFTContracts.length; i++) {
            if (userInfo[_pid][sender].NFTContracts[i] == NFTContract) {
                if (userInfo[_pid][sender].NFTTokenIDs[i] == tokenID) {
                    tokenFound = true;
                    NFTIndex = i;
                    break;
                }
            }
        }
        require(tokenFound == true, "withdrawNFT, token not found");
        userInfo[_pid][sender].nftBoost -= uint112(pointsPerNFT);
        userInfo[_pid][sender].NFTContracts[NFTIndex] = userInfo[_pid][sender]
        .NFTContracts[length - 1];
        userInfo[_pid][sender].NFTContracts.pop();
        userInfo[_pid][sender].NFTTokenIDs[NFTIndex] = userInfo[_pid][sender]
        .NFTTokenIDs[length - 1];
        userInfo[_pid][sender].NFTTokenIDs.pop();
        updateUserWeightedBalance(_pid, sender);
        IERC721(NFTContract).safeTransferFrom(address(this), sender, tokenID);
        emit NFTWithdrawn(sender, NFTContract, tokenID);
    }

    // Stake NFTs, giving the user a bonus point boost defined in pointsPerNFT
    function depositNFT(
        uint256 _pid,
        address NFTContract,
        uint256 tokenID,
        uint256 lockTime
    ) public nonReentrant {
        require(
            msg.sender == tx.origin,
            "boostWithNFT : Deposit from contract disabled"
        );
        require(
            isNFTContract[NFTContract],
            "boostWithNFT: incorrect contract address"
        );
        updatePool(_pid);
        _addToClaimable(_pid, msg.sender);
        IERC721(NFTContract).safeTransferFrom(msg.sender, address(this), tokenID);
        userInfo[_pid][msg.sender].NFTContracts.push(NFTContract);
        userInfo[_pid][msg.sender].NFTTokenIDs.push(tokenID);
        userInfo[_pid][msg.sender].nftBoost += uint112(pointsPerNFT);
        updateUserWeightedBalance(_pid, msg.sender);
        if (lockTime > 0) {
            lockTokens(msg.sender, _pid, lockTime);
        }
        emit NFTStaked(msg.sender, NFTContract, tokenID);
    }

    function addToClaimable(uint256 _pid, address sender) public nonReentrant {
        require(userInfo[_pid][sender].weightedBalance > 0);
        updatePool(_pid);
        _addToClaimable(_pid, sender);
    }

    //add new pool. LP staking should be 0, token staking 1
    function add(
        uint64 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner nonDuplicated(_lpToken) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint64 lastRewardBlock = uint64(
            block.number > startBlock ? block.number : startBlock
        );
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolExistence[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accETHPerShare: 0,
        weightedBalance: 0
        })
        );
    }

    // add nft contract to array
    function addNFTContract(address NFTcontract) public onlyOwner {
        isNFTContract[NFTcontract] = true;
    }

    // transfer non-MW tokens that were sent to staking contract by accident
    function rescueToken(address tokenAddress) public onlyOwner {
        require(
            !poolExistence[IERC20(tokenAddress)],
            "rescueToken : wrong token address"
        );
        uint256 bal = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(msg.sender, bal);
    }

    // update pool allocation points
    function set(
        uint256 _pid,
        uint64 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
        totalAllocPoint -
        poolInfo[_pid].allocPoint +
        _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // start rewards
    function startRewards() public onlyOwner {
        require(
            startBlock > block.number,
            "startRewards: rewards already started"
        );
        startBlock = block.number;
        for (uint256 i; i < poolInfo.length; i++) {
            poolInfo[i].lastRewardBlock = uint64(block.number);
        }
    }

    // check if emergency mode is enabled
    function emergency(bool _isEmergency) public onlyOwner {
        isEmergency = _isEmergency;
        emit Emergency(block.timestamp, _isEmergency);
    }

    // authorize the address
    function authorize(address _address) public onlyOwner {
        authorized[_address] = true;
    }

    // unauthorize the address
    function unauthorize(address _address) public onlyOwner {
        authorized[_address] = false;
    }

    // set new interval for rewards
    function setnumdays(uint256 _days) public onlyOwner {
        require(_days > 0 && _days < 14);
        numdays = _days;
    }

    function claimETH(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.weightedBalance > 0) {
            uint256 ETHPending = ((user.weightedBalance * pool.accETHPerShare) /
            1e12) -
            user.ETHrewardDebt +
            user.claimableETH;
            if (ETHPending > 0) {
                safeETHTransfer(msg.sender, ETHPending);
                user.withdrawn += ETHPending;
                user.ETHrewardDebt =
                (user.weightedBalance * pool.accETHPerShare) /
                1e12;
            }
            user.claimableETH = 0;
        }
    }

    //Lock tokens up to 90 days for rewards boost, (max rewards = x3, rewards increase linearly with lock time)
    function lockTokens(
        address sender,
        uint256 _pid,
        uint256 lockTime
    ) internal {
        UserInfo storage user = userInfo[_pid][sender];
        require(user.nftBoost > 0, "lockTokens: No tokens to lock");
        require(
            user.lockedUntil <= block.timestamp + lockTime,
            "lockTokens: Tokens already locked"
        );
        require(lockTime >= ONE_DAY, "lockTokens: Lock time too short");
        require(lockTime <= 90 * ONE_DAY, "lockTokens: Lock time too long");
        user.lockedUntil = uint32(block.timestamp + lockTime);
        user.lockTimeBoost = uint16((2 * 1000 * lockTime) / (90 * ONE_DAY));
        // 0 - 2000
        updateUserWeightedBalance(_pid, sender);
        emit TokensLocked(sender, block.timestamp, lockTime);
    }

    // calculate and update the user weighted balance
    function updateUserWeightedBalance(uint256 _pid, address _user) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 poolBalance = pool.weightedBalance - user.weightedBalance;
        if (user.lockedUntil < block.timestamp) {
            user.lockTimeBoost = 0;
        }

        user.weightedBalance = ((user.nftBoost *
        (1000 + user.lockTimeBoost)) / 1000);

        pool.weightedBalance = uint112(poolBalance + user.weightedBalance);
        user.ETHrewardDebt =
        (user.weightedBalance * pool.accETHPerShare) /
        1e12;
    }

    function updateETHRewards() internal {
        massUpdatePools();
        ETHPerBlock = ETHLeftUnshared / (7200 * numdays);
    }

    function _addToClaimable(uint256 _pid, address sender) internal {
        UserInfo storage user = userInfo[_pid][sender];
        PoolInfo storage pool = poolInfo[_pid];

        uint256 ETHPending = ((user.weightedBalance * pool.accETHPerShare) /
        1e12) - user.ETHrewardDebt;
        if (ETHPending > 0) {
            user.claimableETH += uint96(ETHPending);
            user.ETHrewardDebt =
            (user.weightedBalance * pool.accETHPerShare) /
            1e12;
        }
    }

    // change taxDistributor address
    function setTaxDistributor(address _TaxDistributor) public onlyOwner {
        TaxDistributor = _TaxDistributor;
    }

    function safeETHTransfer(address _to, uint256 _amount) internal {
        if (_amount > ETHLeftUnclaimed) {
            _amount = ETHLeftUnclaimed;
        }
        payable(_to).transfer(_amount);
        ETHLeftUnclaimed -= _amount;
    }
}
