# Merklelized SKI Calculus

SKI caluclus is the smallest combinatory programming language with three primitives (S,K, I combinators). And every program is a binary tree built strictly from applications via the reduction rules 
- `Kxy -> x`
- `S fgx -> fx(gx)`
- `Ix -> x`

Which is a fully Turing-complete model of computation without variables, which makes it particularly amenable for (intensional programs)[https://www.cs.cmu.edu/~fp/papers/lics01.pdf] (both data and semantics matter). 

In this, we can merklelize the SKI computation graph (which is a DAG) by assigning each node a cryptographic digest of 
- its type (`S`, `K`, `I`, or `App`)
- its children's hashes
- and some nonce/MAC tag

so then every SKI term becomes a Merkle tree and the hash at the root uniquely commits to the program.

Then the moment a reduction step happens, the tree structure changes so the node's hash changes up to the root.    
    - This is the same as a local rewrite in a Merkle leaf causing a global change of commitments