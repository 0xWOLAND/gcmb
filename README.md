# Semantic Hashing of Operational Semantics

The idea of this project is to make use of *semantic hashing*, which cryptographically ocmmits to the intensional structure and reduction behavior of combinatory logic. Similar existing work includes [authenticated data structures](https://dl.acm.org/doi/pdf/10.1145/2535838.2535851), [zero-knowledge virtual machines](https://github.com/rkdud007/awesome-zkvm), [proof-carrying data](https://eprint.iacr.org/2020/1618.pdf) frameworks, etc. These are all ways of (with slightly different features) allowing distrustful parties to perform distributed but verifiable computations. In practice, the hiding factor of ZK-based approaches incurs large runtime costs, so instead I focus on constructing a purely hash-based approach inspired by Andrew Miller's work. In this, we use small-step evaluation in [SKI Calculus](https://en.wikipedia.org/wiki/SKI_combinator_calculus) itself as an authenticated data structure and its operational semantics of the calculus as a hash-indexed, canonical, verifiable object.


In [authenticated data structures](https://dl.acm.org/doi/pdf/10.1145/2535838.2535851), ADSs allow for an untrusted prover to maintain a mutable data structure while a verifier holds a short digest that authenticates the structure. Existing systems apply cryptographic hashing to data structures such as trees, maps, skip-lists, etc. And these systems allow the verifier to check a narrow scope of operations on such structure, but fundamentally computation is treated as external to the data structure itself -- only data is attested to, not general computation. 

Through semantic hashing, we can treat the operational semantics of computation itself as the object of authentication. Instead of hashing data stored in data strctures, we hash the structure of redexes, partial applications, and evaluation contexts. Thus, every reduction state of the SKI calculus receives a canonical cryptographic digest that reflects its semantic form. In this way, it differs from the a checksum (in the way that Git/VCS works) that reflect *syntax*. In doing so, the operaitonal semantics become the authetnicated object in the same way that a Merkle tree authenticates the shaep and contents of a dataset.

> Concerning checksums, it is often the case that two programs can be syntactically distinct but semantically equivalent -- an isssue that traditional hashing won't capture. But SKI terms assign the hash iff they correspond to the same semantic object under the calculus. 

This could be an interesting approach akin to the current suite of verifiable comptuation schemes like SNARK/STARK-based incrementally verifiable computation. There is probably also a way to get succinctness using an [append-only accumulator](https://eprint.iacr.org/2025/234.pdf) (to enforce ordering on the computation trace).

TLDR: 
> We do checksums to the semantics of a program via SKI calculus to get a binding verifiable computation trace.

### What the end product could look like: 
In practice, working directly with SKI calculus isn't a pleasant experience but there are methods of reducing [lambda calculus into SKI calculus](https://thma.github.io/posts/2023-10-08-Optimizing-bracket-abstraction-for-combinator-reduction.html). So a simple example could be implementing a dialect of Lisp on top of this runtime, and in the best case there are a suite of pure deterministic Rust programs (think of the same ones that are currently ingestible by ZKVMs) that could be used by this. In which, a user would simply add a tag to their program that is built directly into the compiler and would be able to make use of this semantic verification system for free. 

Some interesting directions/stuff that needs to be thought about: 
- it really is just a way of attesting to integrity for now, correctness is probably though MACs folded into the hash functoins
- also maybe some weird random oracle stuff that can be done where verifier checks randommly chosen reductions..kind of like freivalds algo for checking matrix multiplications
