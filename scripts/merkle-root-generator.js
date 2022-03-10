const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

const whiteListedAddresses = [
    "0xe69545aac953cd71617921bd1481d6b2cb32d6a5",
    "0x44B5BC42ccDb6c3949e208Bc9e871eAd9342cbAB",
    "0xae2007ca231b3dA9b36A9Ce9Ba3D078Ca3aF7c63",
    "0xb3EE7fc394968BC657BA357D2fB915A9D68D1E93",
];

const whiteListLeafNodes = whiteListedAddresses.map((addr) => keccak256(addr));

const tree = new MerkleTree(whiteListLeafNodes, keccak256, {
    sortPairs: true,
});

const hexRoot = tree.getHexRoot();

console.log("Hex root ", hexRoot);

/** Account 3 */
const leaf = whiteListedAddresses[3];
const hashedAddress = keccak256(leaf);
const proof = tree.getHexProof(hashedAddress);

console.log('white listed account :',leaf);

console.log(proof.join(","));
