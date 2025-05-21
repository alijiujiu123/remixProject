// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "contracts/utils/GrantPrivileges.sol";
// ERC20投票
contract MyERC20Votes is ERC20Votes,GrantPrivileges {
    string public constant TOKEN_NAME="NEZHA_VOTE";
    string public constant TOKEN_SYMBOL="NZ_V";
    constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL) EIP712(TOKEN_NAME, "1") {
        _mint(msg.sender, 10000000000*10**18);
    }
    // 铸币
    function mint(address account, uint256 value) external onlyAdmin {
        _mint(account, value);
    }
    // 销毁
    /**
     * @dev Destroys a `value` amount of tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 value) public virtual {
        _burn(_msgSender(), value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, deducting from
     * the caller's allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `value`.
     */
    function burnFrom(address account, uint256 value) public virtual {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }
    // propposal
    // todo: proposalGroup实现
    error AvailableVotesNotEnough(address account, uint256 proposalId, uint256 allVotes, uint256 usedVoteAmount, uint256 voteAmount);
    struct Proposal {
        uint256 id;
        string description;
        // 总投票数
        uint256 voteCount;
        // 是否开启投票
        bool active;
        // 结束时间
        // account账户投票记录
        mapping(address account => uint256) votes;
    }
    mapping(uint256 => Proposal) public proposals; // 提议ID->提议信息
    uint256 public proposalCounter;
    modifier needProposal(uint256 _id){
        require(proposals[_id].id != 0, "proposal not exist");
        _;
    }
    modifier onlyActive(uint256 _id){
        require(proposals[_id].active, "proposal not active");
        _;
    }

    // 创建proposal
    function createProposal(string memory _description) external onlyAdmin {
        proposalCounter++;
        proposals[proposalCounter].id = proposalCounter;
        proposals[proposalCounter].description = _description;
    }

    // 打开proposal投票,todo: 延时自动打开&自动关闭
    function openProposal(uint256 proposalId) external onlyAdmin needProposal(proposalId) {
        proposals[proposalId].active = true;
    }

    // 关闭proposal投票
    function closeProposal(uint256 proposalId) external onlyAdmin onlyActive(proposalId) {
        proposals[proposalId].active = false;
    }

    // 查看
    function getVotingUnits() public view returns (uint256) {
        return _getVotingUnits(msg.sender);
    }

    // 当前可投票的最大份额(account本身的份额+被人委托的份额)
    function _getVotingUnits(address account) internal  view override  returns (uint256) {
        if (Votes.delegates(account) == address(0) && Votes.getVotes(account) == 0) {
            //account没有委托其他人 && 没有被人委托
            return balanceOf(account);
        }else if (Votes.delegates(account) != address(0) && Votes.getVotes(account) == 0) {
            // account 委托给了其他人 && 没有被人委托
            return 0;
        }else if (Votes.delegates(account) == address(0) && Votes.getVotes(account) != 0) {
            return balanceOf(account)+Votes.getVotes(account);
        }else if (Votes.delegates(account) != address(0) && Votes.getVotes(account) != 0) {
            return Votes.getVotes(account);
        }
        return 0;
    }

    // 投票：todo 投票完成后，token转账后，造成的重复投票问题
    function vote(uint256 proposalId, uint256 voteAmount) external onlyActive(proposalId) {
        // checks
        _validVoteAmount(msg.sender, proposalId, voteAmount);
        // effects
        proposals[proposalId].voteCount += voteAmount;
        proposals[proposalId].votes[msg.sender] += voteAmount;
    }

    // 校验当前投票是否超出最大投票份额
    function _validVoteAmount(address voter, uint256 proposalId, uint256 voteAmount) private view {
        // 当前可用投票额度：当前总可用 - 已用
        uint256 allVotes = _getVotingUnits(voter);
        uint256 usedVoteAmount = proposals[proposalId].votes[voter];
        if (allVotes < usedVoteAmount+voteAmount) {
            revert AvailableVotesNotEnough(voter, proposalId, allVotes, usedVoteAmount, voteAmount);
        }
    }
    
}