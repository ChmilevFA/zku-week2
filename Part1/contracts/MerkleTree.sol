//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[15] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        for(uint i = 0; i < 8; i++){
            hashes[i] = 0;
        }
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        uint treeLevel = 2;
        hashes[index] = hashedLeaf;
        uint currentIndex = index;
        for (uint i = treeLevel; i > 0; i--) {
            if (currentIndex % 2 == 0) {
                hashes[2 ** (treeLevel + 1) - 2 ** i + currentIndex / 2] = PoseidonT3.poseidon([hashes[currentIndex], hashes[currentIndex + 1]]);
            } else {
                hashes[2 ** (treeLevel + 1) - 2 ** i + currentIndex / 2] = PoseidonT3.poseidon([hashes[currentIndex - 1], hashes[currentIndex]]);
            }
            currentIndex = currentIndex / 2 + 2 ** (i + 1);
        }
        index++;
        return hashes[hashes.length - 1];
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        return Verifier.verifyProof(a, b, c, input);
    }
}
