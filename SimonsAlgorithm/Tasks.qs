// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

namespace Quantum.Kata.SimonsAlgorithm {
    
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Measurement;
    
    //////////////////////////////////////////////////////////////////
    // Welcome!
    //////////////////////////////////////////////////////////////////
    
    // "Simon's Algorithm" kata is a series of exercises designed to teach a quantum algorithm for
    // a problem of identifying a bit string that is implicitly defined (or, in other words, "hidden") by
    // some oracle that satisfies certain conditions. It is arguably the most simple case of an (oracle)
    // problem for which a quantum algorithm has a *provable* exponential advantage over any classical algorithm.
    
    // Each task is wrapped in one operation preceded by the description of the task. Each task (except tasks in
    // which you have to write a test) has a unit test associated with it, which initially fails. Your goal is to
    // fill in the blank (marked with // ... comment) with some Q# code to make the failing test pass.
    
    //////////////////////////////////////////////////////////////////
    // Part I. Oracles
    //////////////////////////////////////////////////////////////////
    
    // Task 1.1. f(x) = x₀ ⊕ ... ⊕ xₙ₋₁ (i.e., the parity of a given bit string)
    // Inputs:
    //      1) N qubits in an arbitrary state |x⟩
    //      2) a qubit in an arbitrary state |y⟩
    // Goal: Transform state |x, y⟩ into |x, y ⊕ x₀ ⊕ x₁ ... ⊕ xₙ₋₁⟩ (⊕ is addition modulo 2).
    operation Oracle_CountBits (x : Qubit[], y : Qubit) : Unit is Adj {        
        // 
        for q in x {
            CNOT(q, y);
        }
    }
    
    
    // Task 1.2. Bitwise right shift
    // Inputs:
    //      1) N qubits in an arbitrary state |x⟩
    //      2) N qubits in an arbitrary state |y⟩
    // Goal: Transform state |x, y⟩ into |x, y ⊕ f(x)⟩, where f is bitwise right shift function, i.e.,
    // |y ⊕ f(x)⟩ = |y₀, y₁ ⊕ x₀, y₂ ⊕ x₁, ..., yₙ₋₁ ⊕ xₙ₋₂⟩ (⊕ is addition modulo 2).
    operation Oracle_BitwiseRightShift (x : Qubit[], y : Qubit[]) : Unit is Adj {        
        //
        for i in 0 .. Length(x) - 2 {
            CNOT(x[i], y[i+1]);
        }
    }
    
    
    // Task 1.3. Linear operator
    // Inputs:
    //      1) N qubits in an arbitrary state |x⟩
    //      2) a qubit in an arbitrary state |y⟩
    //      3) a 1xN binary matrix (represented as an Int[]) describing operator A
    //         (see https://en.wikipedia.org/wiki/Transformation_matrix )
    // Goal: Transform state |x, y⟩ into |x, y ⊕ A(x) ⟩ (⊕ is addition modulo 2).
    operation Oracle_OperatorOutput (x : Qubit[], y : Qubit, A : Int[]) : Unit is Adj {
        
        // The following line enforces the constraint on the input arrays.
        // You don't need to modify it. Feel free to remove it, this won't cause your code to fail.
        EqualityFactI(Length(x), Length(A), "Arrays x and A should have the same length");
            
        for i in IndexRange(A) {
            if (A[i] == 1) {
                CNOT(x[i], y);
            }          
        }
    }
    
    
    // Task 1.4. Multidimensional linear operator
    // Inputs:
    //      1) N1 qubits in an arbitrary state |x⟩ (input register)
    //      2) N2 qubits in an arbitrary state |y⟩ (output register)
    //      3) an N2 x N1 matrix (represented as an Int[][]) describing operator A
    //         (see https://en.wikipedia.org/wiki/Transformation_matrix ).
    //         The first dimension of the matrix (rows) corresponds to the output register,
    //         the second dimension (columns) - the input register,
    //         i.e., A[r][c] (element in r-th row and c-th column) corresponds to x[c] and y[r].
    // Goal: Transform state |x, y⟩ into |x, y ⊕ A(x) ⟩ (⊕ is addition modulo 2).
    operation Oracle_MultidimensionalOperatorOutput (x : Qubit[], y : Qubit[], A : Int[][]) : Unit is Adj {
        
        // The following lines enforce the constraints on the input arrays.
        // You don't need to modify them. Feel free to remove them, this won't cause your code to fail.
        EqualityFactI(Length(x), Length(A[0]), "Arrays x and A[0] should have the same length");
        EqualityFactI(Length(y), Length(A), "Arrays y and A should have the same length");
            
        for i in 0 .. Length(A) - 1 {
            for j in 0 .. Length(A[0]) - 1 {
                if (A[i][j] == 1) {
                    CNOT(x[j], y[i]);
                }
            }
        }
    }
    
    
    //////////////////////////////////////////////////////////////////
    // Part II. Simon's Algorithm
    //////////////////////////////////////////////////////////////////
    
    // Task 2.1. State preparation for Simon's algorithm
    // Inputs:
    //      1) N qubits in |0⟩ state (query register)
    // Goal: create an equal superposition of all basis vectors from |0...0⟩ to |1...1⟩ on query register
    // (i.e. the state (|0...0⟩ + ... + |1...1⟩) / sqrt(2ᴺ)).
    operation SA_StatePrep (query : Qubit[]) : Unit is Adj {        
        //
        ApplyToEachCA(H, query);
    }
    
    
    // Task 2.2. Quantum part of Simon's algorithm
    // Inputs:
    //      1) the number of qubits in the input register N for the function f
    //      2) a quantum operation which implements the oracle |x⟩|y⟩ -> |x⟩|y ⊕ f(x)⟩, where
    //         x is N-qubit input register, y is N-qubit answer register, and f is a function
    //         from N-bit strings into N-bit strings
    //
    // The function f is guaranteed to satisfy the following property:
    // there exists some N-bit string s such that for all N-bit strings b and c (b != c)
    // we have f(b) = f(c) if and only if b = c ⊕ s. In other words, f is a two-to-one function.
    //
    // An example of such function is bitwise right shift function from task 1.2;
    // the bit string s for it is [0, ..., 0, 1].
    //
    // Output:
    //      Any bit string b such that Σᵢ bᵢ sᵢ = 0 modulo 2.
    //
    // Note that the whole algorithm will reconstruct the bit string s itself, but the quantum part of the
    // algorithm will only find some vector orthogonal to the bit string s. The classical post-processing
    // part is already implemented, so once you implement the quantum part, the tests will pass.
    operation Simon_Algorithm (N : Int, Uf : ((Qubit[], Qubit[]) => Unit)) : Int[] {
        
        // Declare an Int array in which the result will be stored;
        // the variable has to be mutable to allow updating it.
        mutable b = [];
        // There exist two input strings x1 and x2 that return the same output
        
        // 1. Obtain the first measurement outcome []
        // 2. Repeat until we obtain another measurement outcome [] which equals the first
        // 3. CNOT loop using the 2 inputs that produced the same output
        // 4. Return the solution []
        
        use (x, y) = (Qubit[N], Qubit[N]);

        within { SA_StatePrep(x); }
        apply { Uf(x, y); }

        for i in 0 .. N - 1 {
            // The answer itself will never be a possible outcome (?)
            // Therefore, measurements are guaranteed to return bitstrings orthogonal to the answer
            // We run the quantum part of the algorithm until we have a linearly independent list of bitstrings orthogonal to the answer
            set b += [MResetZ(x[i]) == Zero ? 0 | 1];
        }
        ResetAll(y);

        return b;
    }
    
}
