# Copyright (c) 2024 by Runfeng Yu, All Rights Reserved.

import numpy as np
import os
import math


class SnyderData:
    def __init__(self, file_path, node_num, service_level, max_try):
        self.num_cus = node_num
        self.num_store = node_num
        self.dmd_cus = []
        self.fixed_cost_store = []
        self.dist_matrix = 0

        self.i_0 = -1  # dummy store
        self.I = range(1, self.num_store + 1)  # store
        self.I_bar = [self.i_0] + list(self.I)  # store & dummy store
        self.M = range(self.num_store + 1, self.num_cus + self.num_store + 1)

        self.R = range(1, max_try + 1)  # customer attempts

        self.rho_M = 1
        self.q = service_level

        cost = np.loadtxt(file_path + "cost.csv", delimiter=",")
        demand = np.loadtxt(file_path + "dmd.csv", delimiter=",")
        fixed_cost = np.loadtxt(file_path + "fc.csv", delimiter=",")

        self.pi = cost[0, 1]  # penalty price
        self.dmd_cus = demand
        self.dist_matrix = cost
        self.fixed_cost_store = fixed_cost[1:]
