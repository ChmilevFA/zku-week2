pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

// ref https://github.com/iden3/circomlib/blob/master/circuits/switcher.circom
template swap(){
    signal input swap;
    signal input L;
    signal input R;
    signal output newL;
    signal output newR;

    signal tmp;
    tmp <== (R - L) * swap;
    newL <== tmp + L;
    newR <== - tmp + R;
}

// Given all 2n already hashed leaves of an n-level tree, compute the Merkle root.
template CheckRoot(n) {
    signal input leaves[2**n];
    signal output root;

    var allHashes[(2 ** (n + 1)) - 1];
    component poseidons[2 ** n - 1];

    // assign already hashed leaves
    for (var index = 0; index < 2 ** n; index++) {
        allHashes[index] = leaves[index];
    }

    for (var levelFromTop = n - 1; levelFromTop >= 0; levelFromTop--) {
        var beginOfLevelBelow = (2 ** (n + 1) - 1) - (2 ** (levelFromTop + 2) - 1);
        for (var index = 0; index < 2 ** levelFromTop; index++) {
            var currentHashIndex = beginOfLevelBelow + 2 ** (levelFromTop + 1) + index;
            var currentPoseidonIndex = currentHashIndex - 2 ** n;

            poseidons[currentPoseidonIndex] = Poseidon(2);
            poseidons[currentPoseidonIndex].inputs[0] = allHashes[beginOfLevelBelow + 2 * index];
            poseidons[currentPoseidonIndex].inputs[1] = allHashes[beginOfLevelBelow + 2 * index + 1];

            allHashes[currentHashIndex] = poseidons[currentPoseidonIndex].out;
        }
    }

    root <== allHashes[(2 ** (n + 1)) - 2];
}

// Given an already hashed leaf and all the elements along its path to the root, compute the corresponding root
template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    component swaps[n];
    component poseidons[n];

    for (var index = 0; index < n; index++) {
        swaps[index] = swap();
        swaps[index].L <== (index == 0) ? leaf : poseidons[index - 1].out;
        swaps[index].R <== path_elements[index];
        swaps[index].swap <== path_index[index];

        poseidons[index] = Poseidon(2);
        poseidons[index].inputs[0] <== swaps[index].newL;
        poseidons[index].inputs[1] <== swaps[index].newR;
    }

    root <== poseidons[n - 1].out;
}