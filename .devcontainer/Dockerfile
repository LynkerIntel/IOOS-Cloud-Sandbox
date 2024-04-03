#FROM fedora:41
FROM rockylinux:8.9
ENV HOME "/root"
ENV PATH "${HOME}/.local/bin:${PATH}"
RUN dnf -y update && dnf -y install git gcc-c++ python39-devel which
RUN echo "alias ll='ls -l'" >> ${HOME}/.bashrc
RUN echo "alias python='python3'" >> ${HOME}/.bashrc
RUN python3 -m ensurepip --upgrade && python3 -m pip install --user pipx
RUN pipx install poetry
