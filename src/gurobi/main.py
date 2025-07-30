# Copyright (c) 2025 by Runfeng Yu, All Rights Reserved.

import data
import os
import gc
import logging

from data import SnyderData
from model import Model

cwd = os.getcwd()

for service_level in [0.8, 0.85, 0.9, 0.95]:
    for max_try in [3, 4, 5]:
        for node_num in [15, 49, 88, 150]:
            file_path = cwd + f"/data/snyder/{node_num}nodes/"
            log_path = (
                cwd
                + f"/result/gurobi/snyder/{node_num}nodes/{node_num}-{service_level}-{max_try}.log"
            )
            data = SnyderData(file_path, node_num, service_level, max_try)

            m = Model()
            m.add_first_echelon(data)
            m.add_bops_channel(data)
            m.set_obj(m.cost_fixed, m.cost_bops)
            m.solve_model(log_path)
