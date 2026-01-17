# LR-GTS

This project uses the Lagrangian Relaxation and Granular Tabu Search (LR-GTS) 
method to solve a multi-channel store location problem. 
It serves as the electronic supplement to the following paper:

```
@article{yun2026,
    title = {A multi-channel retail store location model considering customer retry purchasing patterns},
    journal = {Transportation Research Part E: Logistics and Transportation Review},
    volume = {208},
    pages = {104674},
    year = {2026},
    issn = {1366-5545},
    doi = {https://doi.org/10.1016/j.tre.2026.104674},
    author = {Lifen Yun and Runfeng Yu and Hongqiang Fan and Yuanjie Tang and Xun Weng}
}
```

The purpose of the project is to enhance the credibility of the paper and the 
feasibility of experimental replication, and to assist those interested in 
understanding our research.

If you refer to or use the code from this project, please **cite our paper and give this project a star**.


# Required Environment

> ⚠️ MEX files compiled with Matlab 2025a Coder may cause Matlab to crash due to double memory freeing at runtime.

> ⚠️ Matlab versions earlier than 2024b may not support compiling some functions invoking dictionary.

> ⚠️ Gurobi version must >=12. [(Here are the reasons)](https://support.gurobi.com/hc/en-us/community/posts/27254595262993-Add-additional-constraints-but-the-objective-decreased-in-minimize-problem)

- Matlab 2024b 

- Matlab Coder Toolbox

- Matlab Parallel Computing Toolbox

- Supported and compatible compilers for Matlab

- Gurobi (license required)

- Python 3.10+

- gurobipy


# Datasets and Results

The public datasets used include:

http://prodhonc.free.fr/Instances/instancesLRP2E_us.htm

http://prodhonc.free.fr/Instances/instances_us.htm

https://daskin.engin.umich.edu/books/network-discrete-location

All dataset results are included in ```./results``` folder.
Source code (variants) for generating these results are contained **in other branches**.

# Usage Instructions

> If you are new to Matlab Coder, please refer to the introductory documentation:
> 
> https://www.mathworks.com/help/coder/getting-started-with-matlab-coder.html
> 
> Additionally, a compiler must be configured for Coder:
> 
> https://www.mathworks.com/help/coder/gs/setting-up-the-c-c-compiler.html

1. Add the ```src``` folder and its subfolders to the Matlab path.

2. Double-click ```src/lr-gts/Lr_Gts.prj``` (this will open the file in Matlab Coder).

3. In the Coder interface, go to **Step 4: Generate**, choose to compile a MEX 
file, click the ```Generate``` button, and wait for the compilation to finish.
If successful, a ```Lr-Gts.mex*``` file will be generated in the 
```src/lr-gts/``` directory. 
The extension varies by platform (e.g., ```Lr-Gts.mexw64``` on Windows).

4. Run ```Main.m``` after mex file generated.

# Project Structure

```
├── data/
│   ├── nuguyen/                # Nguyen's LRP-2E dataset
│   ├── prodhon/                # Prodhon's LRP-2E dataset
│   ├── snyder/                 # Snyder's dataset (customized)
│   └── tuzun/                  # Tuzun's LRP dataset with capacitated vehicles
│
├── results/                    # results for inputs        
│   ├── nuguyen/                
│   ├── prodhon/               
│   ├── snyder/                
│   └── tuzun/
│
├── src/
│   ├── coder_entry/            # Matlab Coder entry point function
│   ├── data_reader/            # Functions to read data from files
│   ├── granular_tabu_search/   # Granular Tabu Search heuristic
│   ├── gurobi/                 # Gurobi model using Python and gurobipy
│   ├── lagrangian_relaxation/  # Lagrangian Relaxation heuristic
│   ├── lr_gts/                 # LR-GTS heuristic
│   ├── scripts/                # Main function and runners
│   └── utils/                  # Utility tools
│
└── README.md
```

# Acknowledgements

The authors have acknowledged relevant individuals and organizations in the 
paper.
For this code project specifically, the author would like to thank the following
individuals and organizations for their direct or indirect support:

- Prodhon’s personal homepage provides LRP-related datasets, saving us the 
  trouble of collecting them ourselves.
- Beijing Jiaotong University provided a Matlab 2024b license, enabling the use
  of a top-tier scientific computing language.
- Gurobi’s China distributor provided an academic license for Gurobi 12.
- Thanks also to the Gurobi community for their prompt support in resolving the 
  bug we encountered with the solver.
- We recommend [MBeautifier](https://github.com/davidvarga/MBeautifier) for formatting Matlab codes.
