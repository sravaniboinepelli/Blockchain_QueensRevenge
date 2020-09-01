pragma solidity >=0.4.22 <0.8.0;
contract Enc {
    function ggwp() public returns(bytes32){
        uint256 a = 123;
        uint256 b = 10;
        return keccak256(abi.encodePacked(a,b));
    }
}