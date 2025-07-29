# Copyright (c) 2024 by Runfeng Yu, All Rights Reserved.

import numpy as np
import os
import math


class ProdhonData:
    def __init__(self, file_path):
        self.num_cus = 0
        self.num_store = 0
        self.coord_rw = 0
        self.coord_store = []
        self.coord_cus = []
        self.cap_veh_fir = 0
        self.cap_veh_sec = 0
        self.cap_store = []
        self.dmd_cus = []
        self.fixed_cost_store = []
        self.fixed_veh_fir = 0
        self.fixed_veh_sec = 0
        self.dist_matrix = 0
        self.accept_rate = 3
        self.fixed_cost_rate = 10

        self.i_0 = -1  # dummy store
        self.H = range(0, 1)  # warehouse
        self.I = []
        self.I_bar = []
        self.M = []
        self.N = []
        self.S = 0

        self.R = range(1, 5)  # customer attempts
        self.pi = 0  # penalty price
        self.rho_s = 0.1
        self.rho_L = 1
        self.rho_M = 0.1  # bops transportation price
        self.rho_N = None  # os transportation price
        self.q = 0.95  # service level

        with open(file_path, "r", encoding="UTF-8") as file:
            lines = file.readlines()

        self.num_cus = int(lines[0])
        self.num_store = int(lines[1])

        temp = 4
        range_coord_store = range(temp, temp + self.num_store)
        temp += self.num_store + 1

        range_coord_cus = range(temp, temp + self.num_cus)
        temp += self.num_cus + 1

        range_cap_store = range(temp + 3, temp + 3 + self.num_store)
        # print(temp)
        temp += self.num_store + 4

        range_dmd_cus = range(temp, temp + self.num_cus)
        temp += self.num_cus + 1

        range_cost_store = range(temp, temp + self.num_store)
        temp += self.num_store + 1

        count = 0  # 当前步数
        for line in lines:
            if count == 0:
                # 顾客数量
                self.num_cus = int(lines[count])
            elif count == 1:
                # 商店数量
                self.num_store = int(lines[count])
            elif count == 3:
                # 仓库坐标
                self.coord_rw = [[int(x) for x in line.split("\t")]]
            elif count in range_coord_store:
                # 商店坐标
                self.coord_store.append([int(x) for x in line.split("\t")])
            elif count in range_coord_cus:
                # 客户坐标
                self.coord_cus.append([int(x) for x in line.split("\t")])
            elif count == range_coord_cus[-1] + 2:
                # 车辆容量
                self.cap_veh_sec = int(lines[count])
            elif count in range_cap_store:
                # 商店容量
                self.cap_store.append(int(lines[count]))
            elif count in range_dmd_cus:
                # 客户需求
                self.dmd_cus.append(int(lines[count]))
            elif count in range_cost_store:
                # 商店建设成本
                self.fixed_cost_store.append(int(lines[count]))
            elif count == range_cost_store[-1] + 2:
                # 车辆固定成本
                self.fixed_veh_sec = int(lines[count])
            count += 1

        # 计算距离矩阵
        # 索引:
        #   仓库 0
        #   商店 [1, num_store + 1]
        #   客户 [num_store + 1, num_store + num_cus + 1]

        self.dist_matrix = np.zeros(
            (self.num_cus + self.num_store + 1, self.num_cus + self.num_store + 1)
        )
        coord_all = self.coord_rw + self.coord_store + self.coord_cus
        for i in range(0, self.num_cus + self.num_store + 1):
            for j in range(i + 1, self.num_cus + self.num_store + 1):
                # (i,j) i 是起点, j 是终点
                if i == 0:
                    # 第一层
                    self.dist_matrix[i, j] = math.ceil(
                        math.sqrt(
                            (coord_all[i][0] - coord_all[j][0]) ** 2
                            + (coord_all[i][1] - coord_all[j][1]) ** 2
                        )
                        * 100
                    )
                else:
                    # 第二层
                    self.dist_matrix[i, j] = math.ceil(
                        math.sqrt(
                            (coord_all[i][0] - coord_all[j][0]) ** 2
                            + (coord_all[i][1] - coord_all[j][1]) ** 2
                        )
                        * 100
                        * 2
                    )
        temp = self.dist_matrix.T
        self.dist_matrix = self.dist_matrix + temp
        self.S = np.ceil(
            np.mean(self.dist_matrix[1:, 1:]) * self.accept_rate
        )  # acceptable distance
        self.pi = self.dist_matrix[1:, 1:].max() * self.rho_M

        # M和N的价格一致
        self.rho_N = self.rho_M
        self.fixed_cost_store = [
            x * self.fixed_cost_rate for x in self.fixed_cost_store
        ]

        # 集合
        self.I = range(1, self.num_store + 1)  # store
        self.I_bar = [self.i_0] + list(self.I)  # store & dummy store
        self.M = range(
            self.num_store + 1, self.num_cus + self.num_store + 1
        )  # bops customer
        self.N = self.M
        self.L = self.M
        self.K = range(math.ceil((sum(self.dmd_cus) / self.cap_veh_sec) * 1.5))


class NguyenData:
    def __init__(self, file_path):
        self.num_cus = 0
        self.num_store = 0
        self.coord_rw = 0
        self.coord_store = []
        self.coord_cus = []
        self.cap_veh_fir = 0
        self.cap_veh_sec = 0
        self.cap_store = []
        self.dmd_cus = []
        self.fixed_cost_store = []
        self.fixed_veh_fir = 0
        self.fixed_veh_sec = 0
        self.dist_matrix = 0
        self.accept_rate = 3
        self.fixed_cost_rate = 10

        self.i_0 = -1  # dummy store
        self.H = range(0, 1)  # warehouse
        self.I = []
        self.I_bar = []
        self.M = []
        self.N = []
        self.S = 0

        self.R = range(1, 5)  # customer attempts
        self.pi = 0  # penalty price
        self.rho_s = 0.1
        self.rho_L = 1
        self.rho_M = 0.1  # bops transportation price
        self.rho_N = None  # os transportation price
        self.q = 0.95  # service level

        with open(file_path, "r", encoding="UTF-8") as file:
            lines = file.readlines()  # 逐行读

        self.num_store, self.num_cus = [int(x) for x in lines[1].split("\t")]
        self.cap_veh_fir, self.cap_veh_sec = [int(x) for x in lines[2].split("\t")]
        self.fixed_veh_fir, self.fixed_veh_sec = [int(x) for x in lines[3].split("\t")]
        self.coord_rw = [[float(x) for x in lines[4].split("\t")]]

        range_store = range(5, 5 + self.num_store)
        range_cus = range(5 + self.num_store, 5 + self.num_store + self.num_cus)

        count = -1
        for line in lines:
            count += 1

            if count in range(5):
                continue

            if count in range_store:
                temp = [float(x) for x in line.split("\t")]
                self.coord_store.append([temp[0], temp[1]])
                self.fixed_cost_store.append(temp[-1])

            if count in range_cus:
                temp = [float(x) for x in line.split("\t")]
                self.coord_cus.append([temp[0], temp[1]])
                self.dmd_cus.append(temp[2])

        # 计算距离矩阵
        self.dist_matrix = np.zeros(
            (self.num_cus + self.num_store + 1, self.num_cus + self.num_store + 1)
        )
        coord_all = self.coord_rw + self.coord_store + self.coord_cus
        for i in range(0, self.num_cus + self.num_store + 1):
            for j in range(i + 1, self.num_cus + self.num_store + 1):
                # (i,j) i 是起点, j 是终点
                if i == 0:
                    # 第一层
                    self.dist_matrix[i, j] = math.ceil(
                        math.sqrt(
                            (coord_all[i][0] - coord_all[j][0]) ** 2
                            + (coord_all[i][1] - coord_all[j][1]) ** 2
                        )
                        * 10
                    )
                else:
                    # 第二层
                    self.dist_matrix[i, j] = math.ceil(
                        math.sqrt(
                            (coord_all[i][0] - coord_all[j][0]) ** 2
                            + (coord_all[i][1] - coord_all[j][1]) ** 2
                        )
                        * 10
                        * 2
                    )
        temp = self.dist_matrix.T
        self.dist_matrix = self.dist_matrix + temp
        self.S = np.ceil(
            np.mean(self.dist_matrix[1:, 1:]) * self.accept_rate
        )  # acceptable distance
        self.pi = self.dist_matrix[1:, 1:].max() * self.rho_M

        # M和N的价格一致
        self.rho_N = self.rho_M
        self.fixed_cost_store = [
            x * self.fixed_cost_rate for x in self.fixed_cost_store
        ]

        # 集合
        self.I = range(1, self.num_store + 1)  # store
        self.I_bar = [self.i_0] + list(self.I)  # store & dummy store
        self.M = range(
            self.num_store + 1, self.num_cus + self.num_store + 1
        )  # bops customer
        self.N = self.M
        self.L = self.M
        self.K = range(math.ceil((sum(self.dmd_cus) / self.cap_veh_sec) * 1.5))
