# Copyright (c) 2024 by Runfeng Yu, All Rights Reserved.

import gurobipy as gp
import numpy as np
import math
import copy
from copy import deepcopy
import sys
import logging


class Model:
    def __init__(self):
        self.model = gp.Model()

    def add_first_echelon(self, data):
        self.v = self.model.addVars(
            ((i) for i in data.I), vtype=gp.GRB.BINARY, name="v"
        )

        self.cost_fixed = gp.quicksum(
            data.fixed_cost_store[i - 1] * self.v[i] for i in data.I
        )

    def add_os_channel(self, data):
        self.z = self.model.addVars(
            (
                (n, i, k)
                for n in data.N
                for i in list(data.I) + [n]
                for k in self._I_minus_set(data.I, n, i, data.i_0)
            ),
            vtype=gp.GRB.BINARY,
            name="z",
        )

        self.w = self.model.addVars(
            (
                (n, i, k)
                for n in data.N
                for i in list(data.I) + [n]
                for k in self._I_minus_set(data.I, n, i, data.i_0)
            ),
            vtype=gp.GRB.CONTINUOUS,
            ub=1,
            name="w",
        )

        self.cost_os = data.rho_N * gp.quicksum(
            data.dmd_cus[n - data.num_store - 1]
            * gp.quicksum(
                data.dist_matrix[j, i] * self.w[n, j, i]
                for i in data.I
                for j in self._I_plus_set(data.I, n, i, data.i_0)
            )
            for n in data.N
        ) + data.pi * gp.quicksum(
            data.dmd_cus[n - data.num_store - 1]
            * gp.quicksum(
                self.w[n, j, data.i_0]
                for j in self._I_plus_set(data.I, n, data.i_0, data.i_0)
            )
            for n in data.N
        )

        self.model.addConstrs(
            (
                gp.quicksum(
                    self.z[n, k, i] for k in self._I_plus_set(data.I, n, i, data.i_0)
                )
                <= self.v[i]
                for i in data.I
                for n in data.N
            ),
            name="os2open",
        )

        self.model.addConstrs(
            (
                gp.quicksum(
                    self.z[n, n, i] for i in self._I_minus_set(data.I, n, n, data.i_0)
                )
                == 1
                for n in data.N
            ),
            name="osflowstart",
        )

        self.model.addConstrs(
            (
                gp.quicksum(
                    self.z[n, i, data.i_0]
                    for i in self._I_plus_set(data.I, n, data.i_0, data.i_0)
                )
                == 1
                for n in data.N
            ),
            name="osflowend",
        )

        self.model.addConstrs(
            (
                gp.quicksum(
                    self.z[n, i, j] for j in self._I_minus_set(data.I, n, i, data.i_0)
                )
                == gp.quicksum(
                    self.z[n, j, i] for j in self._I_plus_set(data.I, n, i, data.i_0)
                )
                for i in data.I
                for n in data.N
            ),
            name="floweq",
        )

        self.model.addConstrs(
            (
                gp.quicksum(
                    self.z[n, j, i] for j in self._I_plus_set(data.I, n, i, data.i_0)
                )
                <= 1
                for i in data.I
                for n in data.N
            ),
            name="flowle1",
        )

        self.model.addConstrs(
            (
                gp.quicksum(
                    self.z[n, i, j]
                    for i in list(data.I) + [n]
                    for j in self._I_minus_set(data.I, n, i, data.i_0)
                )
                <= data.R[-1]
                for n in data.N
            ),
            name="osattempts",
        )

        self.model.addConstrs(
            (
                self.w[n, n, i] == self.z[n, n, i]
                for n in data.N
                for i in self._I_minus_set(data.I, n, n, data.i_0)
            ),
            name="osprobinit",
        )

        self.model.addConstrs(
            (
                gp.quicksum(
                    self.w[n, i, j] for j in self._I_minus_set(data.I, n, i, data.i_0)
                )
                == (1 - data.q)
                * gp.quicksum(
                    self.w[n, j, i] for j in self._I_plus_set(data.I, n, i, data.i_0)
                )
                for n in data.N
                for i in data.I
            ),
            name="osprob",
        )

        self.model.addConstrs(
            (
                self.w[n, i, j] <= self.z[n, i, j]
                for n in data.N
                for i in data.I
                for j in self._I_minus_set(data.I, n, i, data.i_0)
            ),
            name="probub",
        )

        # self.model.addConstrs(
        #     (
        #         gp.quicksum(
        #             self.z[n, k, i] * data.dist_matrix[k, i]
        #             for i in data.I
        #             for k in self._I_plus_set(data.I, n, i, data.i_0)
        #         )
        #         <= data.S
        #         for n in data.N
        #     ),
        #     name="oslim",
        # )

        self.model.addConstrs(
            (
                gp.quicksum(
                    self.z[n, n, i]
                    for i in self._get_close_I(n, j, data.I, data.dist_matrix)
                )
                + self.v[j]
                <= 1
                for n in data.N
                for j in data.I
            ),
            name="os2nearest",
        )

    def set_obj(self, *args):
        self.model.setObjective(sum(args))

    def solve_model(self, log_name):
        # self.model.Params.OptimalityTol = 1e-9
        # self.model.Params.FeasibilityTol = 1e-9
        self.model.Params.TimeLimit = 1200
        self.model.Params.LogFile = log_name
        self.model.optimize()

    def _get_close_I(self, m, j, I: list, dist_mat):
        # get a store subset from I
        # d[m,i] >= d[m,j]
        result = []
        for i in I:
            if dist_mat[m, i] > dist_mat[m, j]:
                result.append(i)
        return result

    def _I_minus_set(self, I, n, i, i_0):
        # get a subset of I
        # if i \ne n, return I \cup {i_o} \backslash {i}
        # else, return I
        if i == n:
            return list(I)
        else:
            temp = deepcopy(list(I) + [i_0])
            temp.remove(i)
            return temp

    def _I_plus_set(self, I, n, i, i_0):
        # get a subset of I
        # if i \ne i_0, return {n} \cup I \backslash {i}
        # else, return I
        if i != i_0:
            temp = deepcopy([n] + list(I))
            temp.remove(i)
            return temp
        else:
            return list(I)

    def _L_nodes(self, L, I, i):
        if i in I:
            return L
        else:
            temp = deepcopy(list(I) + list(L))
            temp.remove(i)
            return temp
