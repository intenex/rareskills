const { keccak256, solidityKeccak256 } = require("ethers/lib/utils");
const { default: MerkleTree } = require("merkletreejs");

async function createPresaleMerkle(presaleList) {
  let leafNodes = presaleList.map((obj) =>
    solidityKeccak256(["uint256", "address"], [obj.bitmapNumber, obj.address])
  );
  return new MerkleTree(leafNodes, keccak256, { sortPairs: true });
}

module.exports = {
  createPresaleMerkle,
};
