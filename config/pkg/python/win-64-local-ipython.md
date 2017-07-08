# Jupyter, machine learning on Windows in vscode

## anaconda
https://www.continuum.io/downloads
https://repo.continuum.io/archive/.winzip/

[anaconda install documentation](https://docs.continuum.io/anaconda/install)

## miniconda (smaller distro)

[miniconda home](https://conda.io/miniconda.html)

[Instructions](https://conda.io/docs/install/quick.html#windows-miniconda-install)


## Jupyter

[Jupyter Install Document](http://jupyter.readthedocs.io/en/latest/install.html)

ext install jupyter

### pip

see [pip package index here](https://pypi.python.org/pypi)

pip3 install jupyter
pip3 install matplotlib
pip3 install pandas


<!-- EVEN THOUGH NUMPY CAN BE INSTALLED WITH PIP3; I NEED
numpy+mkl ; WHICH IS THE INTEL MATH-KERNEL LIBRARY -->
<!-- scipy - The binary wheel was required -->
pip3 install scikit-learn
pip3 install tensorflow



> I added `python\` and `python\Scripts\` to the **PATH**

jupyter-notebook.exe --no-browser --port=8888 --NotebookApp.allow_origin=\"*\" --notebook-dir='~/Downloads/_jupyter-notebooks'



### Dependencies - binary python packages (Wheels)

I _believe_ that most of these packages require a C compiler, and specifically the MSVC2015 C Compiler. So in the interest of making installation easier, we will use these binary packages.

[about installing from wheels](https://pip.pypa.io/en/latest/user_guide/#installing-from-wheels)

from <http://www.lfd.uci.edu/~gohlke/pythonlibs/> you'll need to download the wheels for:  
- [NumPy](http://www.lfd.uci.edu/~gohlke/pythonlibs/#numpy)  
      for `numpy‑1.13.0rc1+mkl‑cp36‑cp36m‑win_amd64.whl`

      pip3 install C:\Users\ehiller\AppData\Local\omega\config\pkg\python\binaries\numpy-1.13.0rc1+mkl-cp36-cp36m-win_amd64.whl
- [SciPy](http://www.lfd.uci.edu/~gohlke/pythonlibs/#scipy)  
      for `scipy‑0.19.0‑cp36‑cp36m‑win_amd64.whl`

      pip3 install C:\Users\ehiller\AppData\Local\omega\config\pkg\python\binaries\scipy-0.19.0-cp36-cp36m-win_amd64.whl
- [scikit-learn, aka sklearn](http://www.lfd.uci.edu/~gohlke/pythonlibs/#scikit-learn)  
      for `scikit_learn‑0.18.1‑cp36‑cp36m‑win_amd64.whl`

      pip3 install C:\Users\ehiller\AppData\Local\omega\config\pkg\python\binaries\scikit_learn-0.18.1-cp36-cp36m-win_amd64.whl

- [tensorflow](http://www.lfd.uci.edu/~gohlke/pythonlibs/#tensorflow)  
      for `tensorflow‑1.1.0‑cp36‑cp36m‑win_amd64.whl`

      pip3 install C:\Users\ehiller\AppData\Local\omega\config\pkg\python\binaries\tensorflow-1.1.0-cp36-cp36m-win_amd64.whl

