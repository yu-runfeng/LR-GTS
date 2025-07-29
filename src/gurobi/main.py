# Copyright (c) 2024 by Runfeng Yu, All Rights Reserved.

import data
import os
import gc
import logging

from data import ProdhonData, NguyenData
from model import Model

# Prodhon LRP-2E
folder_path = "../../data/prodhon/"
file_names = os.listdir(folder_path)
file_names.sort()
for f_name in file_names:
    data_path = folder_path + f_name
    log_path = "../../result" + data_path[5:-4] + ".log"
    print(log_path)

    try:
        data = ProdhonData(data_path)
        m = Model()

        m.add_first_echelon(data)
        m.add_sfs_channel(data)
        m.add_bops_channel(data)
        m.add_os_channel(data)
        m.add_coupled_constr(data)
        m.set_obj(m.cost_fixed, m.cost_trans, m.cost_sfs, m.cost_bops, m.cost_os)

        m.solve_model(log_path)
        m.print_sol(data, log_path)

        del m
        del data
        gc.collect()

    except BaseException:
        logging.basicConfig(
            filename=log_path, level=logging.INFO, filemode="a", format="%(message)s"
        )
        logging.info("FAIL")
        for handler in logging.root.handlers[:]:
            logging.root.removeHandler(handler)
            handler.close()

# Nguyen LRP-2E
folder_path = "../../data/nguyen/"
file_names = os.listdir(folder_path)
file_names.sort()

for f_name in file_names:
    data_path = folder_path + f_name
    log_path = "../../result" + data_path[5:-4] + ".log"
    print(log_path)

    try:
        data = NguyenData(data_path)
        m = Model()

        m.add_first_echelon(data)
        m.add_sfs_channel(data)
        m.add_bops_channel(data)
        m.add_os_channel(data)
        m.add_coupled_constr(data)
        m.set_obj(m.cost_fixed, m.cost_trans, m.cost_sfs, m.cost_bops, m.cost_os)

        m.solve_model(log_path)
        m.print_sol(data, log_path)

        del m
        del data
        gc.collect()

    except BaseException:
        logging.basicConfig(
            filename=log_path, level=logging.INFO, filemode="a", format="%(message)s"
        )
        logging.info("FAIL")
        for handler in logging.root.handlers[:]:
            logging.root.removeHandler(handler)
            handler.close()
