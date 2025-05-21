// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "contracts/utils/GrantPrivileges.sol";
// 接口
interface IERC721Transfer {
    function transfer(address to, uint256 tokenId) external;
}
// 抽象合约
abstract contract ERC721Transfer is IERC721Transfer {
    // token计数器
    uint256 internal tokenCounter;
    // NFT最大值
    uint256 internal constant limit = 10;
    event MESTransfer(address indexed from, address indexed to, uint256 indexed tokenId);
    // 定义trans
}
// 合约具体实现
contract MyERC721 is ERC721Transfer,GrantPrivileges,ERC721URIStorage {
    // 构造函数
    // ERC721()构造函数设置NFT名称和符号
    // GrantPrivileges()构造函数设置adminAddress
    constructor() ERC721("MyERC721Name","MES") GrantPrivileges() {
        // 将第一个NFT铸造给合约发布者(0号NFT)
        mint(msg.sender, "https://image.baidu.com/search/detail?ct=503316480&z=undefined&tn=baiduimagedetail&ipn=d&word=%E5%9B%BE%E7%89%87&step_word=&lid=8967644813760151188&ie=utf-8&in=&cl=2&lm=-1&st=undefined&hd=undefined&latest=undefined&copyright=undefined&cs=2879033369,2612231413&os=3275602674,3232934661&simid=2879033369,2612231413&pn=0&rn=1&di=7451266606379827201&ln=502&fr=&fmq=1736933981849_R&fm=&ic=undefined&s=undefined&se=&sme=&tab=0&width=undefined&height=undefined&face=undefined&is=3275602674,3232934661&istype=0&ist=&jit=&bdtype=0&spn=0&pi=0&gsm=1e&objurl=https%3A%2F%2Fp6-pc-sign.douyinpic.com%2Ftos-cn-i-0813%2F9efdd06d4fa948ae9a1a260a279fe997~tplv-dy-aweme-images%3Aq75.webp%3Fbiz_tag%3Daweme_images%26from%3D3213915784%26s%3DPackSourceEnum_AWEME_DETAIL%26se%3Dfalse%26x-expires%3D1680699600%26x-signature%3DSGnSCgQKG3ORqFVHzsrnJcVNAfU%253D&rpstart=0&rpnum=0&adpicid=0&nojc=undefined&dyTabStr=MCwxMiwzLDEsMiwxMyw3LDYsNSw5");
    }
    // 铸造NFT: 给指定地址铸造一个NFT，并绑定代币URI（只有admin权限才能操作）
    function mint(address to, string memory tokenURI) public onlyAdmin returns (uint256) {
        require(tokenCounter < limit, "nft circulation has reached the upper limit");
        uint256 newTokenId = ERC721Transfer.tokenCounter++;
        // 调用内部函数完成铸造
        _mint(to, newTokenId);
        // 绑定tokenURI
        _setTokenURI(newTokenId, tokenURI);
        return ERC721Transfer.tokenCounter;
    } 
    // 销毁NFT
    function burn(uint256 tokenId) public {
        // 只有token的持有者或授权者才能销毁
//        require(_isApprovedOrOwner(_msgSender(), tokenId), "only approved or owner can burn");
        require(isApprovedOrOwner(_msgSender(), tokenId), "only approved or owner can burn");
        _burn(tokenId);
    }
    // 获取当前NFT数量
    function getTokenCounter() external view returns (uint256) {
        return ERC721Transfer.tokenCounter;
    }
    // 查询sender是否为NFT拥有者或授权者
    function isApprovedOrOwner(address sender, uint256 tokenId) private view returns (bool) {
        return _ownerOf(tokenId)==sender || _getApproved(tokenId)==sender;
    }
    // IERC721Transfer定义抽象方法transfer实现
    function transfer(address to, uint256 tokenId) external {
        emit MESTransfer(_msgSender(), to, tokenId);
        safeTransferFrom(_msgSender(), to, tokenId);
    }
    // 获取nft代币上限
    function getLimit() external pure returns (uint256) {
        return limit;
    }
}