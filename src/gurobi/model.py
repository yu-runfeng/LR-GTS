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

        self.dmd_store = self.model.addVars(
            ((i) for i in data.I), vtype=gp.GRB.CONTINUOUS, name="Lambda"
        )

        self.cost_trans = data.rho_s * gp.quicksum(
            self.dmd_store[i] * data.dist_matrix[0, i] for i in data.I
        )

        self.cost_fixed = gp.quicksum(
            data.fixed_cost_store[i - 1] * self.v[i] for i in data.I
        )

    def add_sfs_channel(self, data):
        self.x = self.model.addVars(
            (
                (i, j, k)
                for i in list(data.I) + list(data.L)
                for j in self._L_nodes(data.L, data.I, i)
                for k in data.K
            ),
            vtype=gp.GRB.BINARY,
            name="x",
        )

        self.u = self.model.addVars(
            ((i, l) for i in data.I for l in data.L),
            vtype=gp.GRB.BINARY,
            name="u",
        )

        self.mu = self.model.addVars(
            ((i, k) for i in data.L for k in data.K),
            vtype=gp.GRB.CONTINUOUS,
            ub=data.cap_veh_sec,
            name="mu",
        )

        self.cost_sfs = data.rho_L * gp.quicksum(
            data.dist_matrix[i, j] * gp.quicksum(self.x[i, j, k] for k in data.K)
            for i in list(data.I) + list(data.L)
            for j in self._L_nodes(data.L, data.I, i)
        ) + data.fixed_veh_sec * gp.quicksum(
            self.x[i, j, k] for i in data.I for j in data.L for k in data.K
        )

        self.model.addConstrs(
            (self.u[i, l] <= self.v[i] for i in data.I for l in data.L), name="sfs2open"
        )

        self.model.addConstrs(
            (
                gp.quicksum(
                    self.x[i, j, k]
                    for k in data.K
                    for i in self._L_nodes(data.L, data.I, j)
                )
                == 1
                for j in data.L
            ),
            name="sfs_serv",
        )

        self.model.addConstrs(
            (
                gp.quicksum(self.x[i, j, k] for j in self._L_nodes(data.L, data.I, i))
                == gp.quicksum(
                    self.x[j, i, k] for j in self._L_nodes(data.L, data.I, i)
                )
                for i in list(data.I) + list(data.L)
                for k in data.K
            ),
            name="sfseq",
        )

        self.model.addConstrs(
            (
                gp.quicksum(self.x[i, j, k] for i in data.I for j in data.L) <= 1
                for k in data.K
            ),
            name="sfs_start",
        )

        self.model.addConstrs(
            (
                gp.quicksum(
                    data.dmd_cus[j - data.num_store - 1]
                    * gp.quicksum(
                        self.x[i, j, k] for i in self._L_nodes(data.L, data.I, j)
                    )
                    for j in data.L
                )
                <= data.cap_veh_sec
                for k in data.K
            ),
            name="sfscap",
        )

        self.model.addConstrs(
            (
                gp.quicksum(self.x[i, j, k] for j in self._L_nodes(data.L, data.I, i))
                + gp.quicksum(self.x[j, l, k] for j in self._L_nodes(data.L, data.I, l))
                <= 1 + self.u[i, l]
                for i in data.I
                for l in data.L
                for k in data.K
            ),
            name="sfsassign",
        )

        self.model.addConstrs(
            self.mu[i, k] - self.mu[j, k] + data.cap_veh_sec * self.x[i, j, k]
            <= data.cap_veh_sec - data.dmd_cus[j - data.num_store - 1]
            for i in data.L
            for j in self._L_nodes(data.L, [], i)
            for k in data.K
        )

    def add_bops_channel(self, data):
        self.y = self.model.addVars(
            ((m, i, r) for m in data.M for i in data.I_bar for r in data.R),
            vtype=gp.GRB.BINARY,
            name="y",
        )

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
        self.model.addConstrs(
            (
                data.dist_matrix[m, i] * self.y[m, i, r] <= data.S
                for m in data.M
                for i in data.I
                for r in range(1, data.R[-1])
            ),
            name="bopslim",
        )

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

        self.model.addConstrs(
            (
                gp.quicksum(
                    self.z[n, k, i] * data.dist_matrix[k, i]
                    for i in data.I
                    for k in self._I_plus_set(data.I, n, i, data.i_0)
                )
                <= data.S
                for n in data.N
            ),
            name="oslim",
        )

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

    def add_coupled_constr(self, data):
        self.model.addConstrs(
            self.dmd_store[i]
            == gp.quicksum(
                data.dmd_cus[m - data.num_store - 1] * self.y[m, i, 1] for m in data.M
            )
            + gp.quicksum(
                data.dmd_cus[n - data.num_store - 1] * self.z[n, n, i] for n in data.N
            )
            + gp.quicksum(
                data.dmd_cus[l - data.num_store - 1] * self.u[i, l] for l in data.L
            )
            for i in data.I
        )

    def set_obj(self, *args):
        self.model.setObjective(sum(args))

    def solve_model(self, log_name):
        # self.model.Params.OptimalityTol = 1e-9
        # self.model.Params.FeasibilityTol = 1e-9
        self.model.Params.TimeLimit = 3600
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

    def print_sol(self, data, log_name):
        logging.basicConfig(
            filename=log_name, level=logging.INFO, filemode="a", format="%(message)s"
        )
        logging.info("--------------------------------")
        logging.info(log_name)
        logging.info("--------------------------------")
        if (self.model.Status == gp.GRB.TIME_LIMIT) or (
            self.model.Status == gp.GRB.OPTIMAL
        ):
            try:
                logging.info("All costs: ")
                logging.info(f"Fixed Cost: \t{self.cost_fixed.getValue()}")
                logging.info(f"Trans Cost: \t{self.cost_trans.getValue()}")
                logging.info(f"SFS Cost:   \t{self.cost_sfs.getValue()}")
                logging.info(f"BOPS Cost:  \t{self.cost_bops.getValue()}")
                logging.info(f"OS Cost:    \t{self.cost_os.getValue()}")
                logging.info("--------------------------------")

                # 选址
                store_built = [
                    i for i in data.I if math.isclose(self.v[i].X, 1, abs_tol=1e-3)
                ]
                logging.info("location: {}".format(store_built))
                logging.info(
                    f"loc cost: {sum([data.fixed_cost_store[i-1] for i in store_built])}"
                )
                logging.info("--------------------------------")

                # SFS 渠道
                logging.info("SFS: ")
                for k in data.K:
                    l_exp = gp.quicksum(
                        self.x[i, j, k]
                        for i in data.L
                        for j in self._L_nodes(data.L, data.I, i)
                    )
                    if math.isclose(l_exp.getValue(), 0, abs_tol=1e-3):
                        logging.info(f"veh[{k}]: empty")
                        continue

                    # 起点
                    route_k = []
                    for i in data.I:
                        l_exp = gp.quicksum(
                            self.x[i, j, k] for j in self._L_nodes(data.L, data.I, i)
                        )
                        if math.isclose(l_exp.getValue(), 1, abs_tol=1e-3):
                            route_k.append(i)
                            break

                    # 中间点
                    while 1:
                        for i in self._L_nodes(data.L, data.I, route_k[-1]):
                            if math.isclose(
                                self.x[route_k[-1], i, k].X, 1, abs_tol=1e-3
                            ):
                                route_k.append(i)
                                if i in data.I:
                                    break
                        if route_k[-1] in data.I and len(route_k) >= 2:
                            break
                    logging.info(f"veh[{k}]: {route_k}")
                logging.info("--------------------------------")

                # BOPS 渠道
                logging.info("BOPS: ")
                for m_ind in data.M:
                    stores_m = []
                    for r in data.R:
                        for i in data.I_bar:
                            if math.isclose(self.y[m_ind, i, r].X, 1, abs_tol=1e-3):
                                stores_m.append(i)
                    logging.info(f"cus [{m_ind}]: {stores_m}")
                logging.info("--------------------------------")

                # OS 渠道
                logging.info("OS: ")
                for n in data.N:
                    stores_n = [n]
                    while 1:
                        for k in self._I_minus_set(data.I, n, stores_n[-1], data.i_0):
                            if math.isclose(
                                self.z[n, stores_n[-1], k].X, 1, abs_tol=1e-3
                            ):
                                stores_n.append(k)
                                if k == data.i_0:
                                    break
                        if stores_n[-1] == data.i_0:
                            break
                    logging.info(f"cus [{n}]: {stores_n}")

                # 输出参数取值
                logging.info("-----------------------------")
                logging.info(f"data.num_cus = {data.num_cus}")
                logging.info(f"data.num_store = {data.num_store}")
                logging.info(f"data.coord_rw = {data.coord_rw}")
                logging.info(f"data.coord_store = {data.coord_store}")
                logging.info(f"data.coord_cus = {data.coord_cus}")
                logging.info(f"data.cap_veh_fir = {data.cap_veh_fir}")
                logging.info(f"data.cap_veh_sec = {data.cap_veh_sec}")
                logging.info(f"data.cap_store = {data.cap_store}")
                logging.info(f"data.dmd_cus = {data.dmd_cus}")
                logging.info(f"data.fixed_cost_store = {data.fixed_cost_store}")
                logging.info(f"data.fixed_veh_fir = {data.fixed_veh_fir}")
                logging.info(f"data.fixed_veh_sec = {data.fixed_veh_sec}")
                logging.info(f"data.dist_matrix = {data.dist_matrix}")
                logging.info(f"data.accept_rate = {data.accept_rate}")
                logging.info(f"data.fixed_cost_rate = {data.fixed_cost_rate}")
                logging.info(f"data.i_0 = {data.i_0}")
                logging.info(f"data.H = {data.H}")
                logging.info(f"data.I = {data.I}")
                logging.info(f"data.I_bar = {data.I_bar}")
                logging.info(f"data.M = {data.M}")
                logging.info(f"data.N = {data.N}")
                logging.info(f"data.S = {data.S}")
                logging.info(f"data.R = {data.R}")
                logging.info(f"data.pi = {data.pi}")
                logging.info(f"data.rho_s = {data.rho_s}")
                logging.info(f"data.rho_L = {data.rho_L}")
                logging.info(f"data.rho_M = {data.rho_M}")
                logging.info(f"data.rho_N = {data.rho_N}")
                logging.info(f"data.q = {data.q}")
                logging.info("-----------------------------")

            except BaseException:
                logging.info("gurobi fail")
                logging.info(self.model.Status)
                logging.info("-----------------------------")

        for handler in logging.root.handlers[:]:
            logging.root.removeHandler(handler)
            handler.close()
