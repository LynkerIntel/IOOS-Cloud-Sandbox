FROM redhat/ubi8:8.10
ENV HOME="/root"
ENV PATH="${HOME}/.local/bin:${PATH}"
RUN <<SCRIPT1
dnf -y update
echo "alias ll='ls -l'" >> ${HOME}/.bashrc
echo "alias python='python3'" >> ${HOME}/.bashrc
dnf -y install git gcc-c++ python3-devel which
python3 -m ensurepip --upgrade && python3 -m pip install --user pipx
pipx install poetry
dnf -y install gcc-gfortran
SCRIPT1
RUN dnf install -y procps-ng