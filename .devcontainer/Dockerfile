FROM infrastructurebuilder/ansible-container:latest
ENV HOME "/root"
ENV PATH "${HOME}/.local/bin:${PATH}"
RUN dnf -y update
RUN echo "alias ll='ls -l'" >> ${HOME}/.bashrc
RUN echo "alias python='python3'" >> ${HOME}/.bashrc
RUN dnf -y install git gcc-c++ python3-devel which
RUN python3 -m ensurepip --upgrade && python3 -m pip install --user pipx
RUN pipx install poetry
RUN dnf -y install gcc-gfortran
