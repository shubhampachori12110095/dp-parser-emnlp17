#!/usr/bin/env python
# encoding: utf-8

cimport cython
cimport numpy as np
import numpy as np

np.import_array()

cdef np.float64_t NEGINF = -np.inf
cdef np.float64_t INF = np.inf
cdef inline int int_max(int a, int b): return a if a >= b else b
cdef inline int int_min(int a, int b): return a if a <= b else b
cdef inline np.float64_t float64_max(np.float64_t a, np.float64_t b): return a if a >= b else b
cdef inline np.float64_t float64_min(np.float64_t a, np.float64_t b): return a if a <= b else b


@cython.boundscheck(False)
@cython.wraparound(False)
def parse_ah_dp_mst(np.ndarray[ndim=3, dtype=np.float64_t] transition_scores, np.ndarray[ndim=2, dtype=np.float64_t] mst_scores):
    cdef int nr, nc, _, N, i, j, k, r
    cdef np.ndarray[ndim=2, dtype=np.float64_t] table
    cdef np.float64_t tmp, cand
    cdef np.ndarray[ndim=2, dtype=np.npy_intp] backtrack
    cdef np.ndarray[ndim=2, dtype=np.npy_intp] backtrack_type
    cdef np.ndarray[ndim=1, dtype=np.npy_intp] transitions
    cdef np.ndarray[ndim=1, dtype=np.npy_intp] pred_heads

    nr, nc, _ = np.shape(transition_scores)

    table = np.full((nr, nr), NEGINF)
    backtrack = np.full((nr, nr), 0, dtype=int)
    backtrack_type = np.full((nr, nr), 0, dtype=int)
    transitions = np.full(2*(nr-2)-1, -1, dtype=int)
    pred_heads = np.full(nr - 2, -1, dtype=int)

    for j in range(0, nr - 1):
        table[j, j + 1] = 0.

    for r in range(2, nr):
        for i in range(0, nr - r):
            j = i + r
            for k in range(i + 1, j):
                if j < nr - 1:
                    tmp = table[i, k] + table[k, j] + transition_scores[i, k, 0] + transition_scores[k, j, 1] + mst_scores[j-1, k-1]
                    if tmp > table[i, j]:
                        table[i, j] = tmp
                        backtrack[i, j] = k
                        backtrack_type[i, j] = 1
                if i > 0:
                    tmp = table[i, k] + table[k, j] + transition_scores[i, k, 0] + transition_scores[k, j, 2] + mst_scores[i-1, k-1]
                    if tmp > table[i, j]:
                        table[i, j] = tmp
                        backtrack[i, j] = k
                        backtrack_type[i, j] = 2

    backtrack_ah_dp_mst(backtrack, backtrack_type, 1, nr-1, 0, transitions, pred_heads)
    return transitions, pred_heads


@cython.boundscheck(False)
@cython.wraparound(False)
cdef int backtrack_ah_dp_mst(np.ndarray[ndim=2, dtype=np.npy_intp] backtrack, np.ndarray[ndim=2, dtype=np.npy_intp] backtrack_type, int i, int j, int cur_pos, np.ndarray[ndim=1, dtype=np.npy_intp] transitions, np.ndarray[ndim=1, dtype=np.npy_intp] heads):
    cdef int new_pos, k
    if j == i + 1:
        transitions[cur_pos] = 0
        return cur_pos + 1
    else:
        k = backtrack[i, j]
        new_pos = backtrack_ah_dp_mst(backtrack, backtrack_type, i, k, cur_pos, transitions, heads)
        new_pos = backtrack_ah_dp_mst(backtrack, backtrack_type, k, j, new_pos, transitions, heads)
        transitions[new_pos] = backtrack_type[i, j]
        if backtrack_type[i, j] == 1:
            heads[k - 1] = j - 1
        elif backtrack_type[i, j] == 2:
            heads[k - 1] = i - 1
        new_pos += 1
        return new_pos
