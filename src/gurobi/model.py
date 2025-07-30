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
        # data = ProdhonData(path)
        self.model = gp.Model()

    def add_first_echelon(self, data):
        self.v = self.model.addVars(
            ((i) for i in data.I), vtype=gp.GRB.BINARY, name="v"
        )

        self.cost_fixed = gp.quicksum(
            data.fixed_cost_store[i - 1] * self.v[i] for i in data.I
        )

    def add_bops_channel(self, data):
        # 添加BOPS渠道相关的变量\成本\约束
        # BOPS决策变量
        self.y = self.model.addVars(
            ((m, i, r) for m in data.M for i in data.I_bar for r in data.R),
            vtype=gp.GRB.BINARY,
            name="y",
        )

        # BOPS渠道成本
        self.cost_bops = data.rho_M * gp.quicksum(
            data.dmd_cus[m - data.num_store - 1]
            * gp.quicksum(
                data.dist_matrix[m, i]
                * (1 - data.q) ** (r - 1)
                * data.q
                * self.y[m, i, r]
                for i in data.I
                for r in data.R
            )
            for m in data.M
        ) + data.pi * gp.quicksum(
            data.dmd_cus[m - data.num_store - 1]
            * gp.quicksum(
                (1 - data.q) ** (r - 1) * self.y[m, data.i_0, r] for r in data.R
            )
            for m in data.M
        )

        # BOPS渠道约束
        self.model.addConstrs(
            (
                gp.quicksum(self.y[m, i, r] for r in data.R) <= self.v[i]
                for i in data.I
                for m in data.M
            ),
            name="bops2open",
        )

        # \sum_{i\in I\cup\{i_0\}} y_{ir}^m + \sum_{s=1}^{r-1} y_{i_0s}^m = 1,
        # \forall m\in M,r=1,\ldots,R
        self.model.addConstrs(
            (
                gp.quicksum(self.y[m, i, r] for i in data.I_bar)
                + gp.quicksum(self.y[m, data.i_0, s] for s in range(1, r))
                == 1
                for m in data.M
                for r in data.R
            ),
            name="bops2store",
        )

        # \sum_{r=2}^R y_{i_0r}^m = 1, \forall m\in M
        self.model.addConstrs(
            (
                gp.quicksum(self.y[m, data.i_0, r] for r in data.R[1:]) == 1
                for m in data.M
            ),
            name="bopslv",
        )

        # d_{mi} y_{ir}^m \le S, \forall m\in M,i\in I,r=1,\ldots,R-1
        # self.model.addConstrs(
        #     (
        #         data.dist_matrix[m, i] * self.y[m, i, r] <= data.S
        #         for m in data.M
        #         for i in data.I
        #         for r in range(1, data.R[-1])
        #     ),
        #     name="bopslim",
        # )

        # \sum_{i:d_{mi}>d_{mj}} y_{i1}^m + v_j \le 1, \forall m\in M, j\in I
        self.model.addConstrs(
            (
                gp.quicksum(
                    self.y[m, i, 1]
                    for i in self._get_close_I(m, j, data.I, data.dist_matrix)
                )
                + self.v[j]
                <= 1
                for m in data.M
                for j in data.I
            ),
            name="bopsnearest",
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
        # else, return I \cup {i_o}
        if i == n:
            return list(I) + [i_0]
        else:
            temp = deepcopy(list(I) + [i_0])
            temp.remove(i)
            return temp

    def _I_plus_set(self, I, n, i, i_0):
        # get a subset of I
        # if i \ne i_0, return {n} \cup I \backslash {i}
        # else, return {n} \cup I
        if i != i_0:
            temp = deepcopy([n] + list(I))
            temp.remove(i)
            return temp
        else:
            return [n] + list(I)

    def _L_nodes(self, L, I, i):
        if i in I:
            return L
        else:
            temp = deepcopy(list(I) + list(L))
            temp.remove(i)
            return temp
