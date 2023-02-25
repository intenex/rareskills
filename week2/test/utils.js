const { keccak256, solidityKeccak256 } = require("ethers/lib/utils");
const { default: MerkleTree } = require("merkletreejs");

async function createPresaleMerkleBitmap(presaleList) {
  let leafNodes = presaleList.map((obj) =>
    solidityKeccak256(["uint256", "address"], [obj.bitmapNumber, obj.address])
  );
  return new MerkleTree(leafNodes, keccak256, { sortPairs: true });
}

async function createPresaleMerkleMapping(presaleList) {
  let leafNodes = presaleList.map((obj) =>
    solidityKeccak256(["address"], [obj.address])
  );
  return new MerkleTree(leafNodes, keccak256, { sortPairs: true });
}

module.exports = {
  createPresaleMerkleBitmap,
  createPresaleMerkleMapping,
};
