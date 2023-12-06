// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract MyNFT is ERC721URIStorage, OwnerIsCreator {
    // string constant TOKEN_URI =
    //     "https://ipfs.io/ipfs/QmYuKY45Aq87LeL1R5dhb1hqHLp6ZFbJaCP8jxqKM1MX6y/babe_ruth_1.json";
    uint256 internal tokenId;

    constructor() ERC721("MyNFT", "MNFT"){}

    function mint(address to, string memory TOKEN_URI) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, TOKEN_URI);
        unchecked {
            tokenId++;
        }
    }
}
contract CrossNftDestinationMinter is CCIPReceiver, OwnerIsCreator{
    MyNFT public nft;
    uint256 price;

    event MintCallSuccessfull();

    constructor(address router, uint256 _price) CCIPReceiver(router) {
        nft = new MyNFT();
        price = _price;
    }

    mapping(uint64 => bool) public whitelistedSourceChains;
    mapping(address => bool) public whitelistedSenders;

    event MintCallSuccessfull();

    error SourceChainNotWhitelisted(uint64 sourceChainSelector);
    error SenderNotWhitelisted(address sender);

    modifier onlyWhitelistedSourceChain(uint64 _sourceChainSelector) {
        if (!whitelistedSourceChains[_sourceChainSelector])
            revert SourceChainNotWhitelisted(_sourceChainSelector);
        _;
    }

    modifier onlyWhitelistedSenders(address _sender) {
        if (!whitelistedSenders[_sender]) revert SenderNotWhitelisted(_sender);
        _;
    }


    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        require(message.destTokenAmounts[0].amount >= price, "Not enough CCIP-BnM for mint");
        (bool success, ) = address(nft).call(message.data);
        require(success);
        emit MintCallSuccessfull();
    }
}