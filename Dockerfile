FROM nvcr.io/nvidia/tensorflow:20.01-tf2-py3

ARG NB_USER=user
ARG NB_UID=1000
ARG NB_GID=1000

RUN groupadd wheel -g 11 && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER 

RUN apt update -yq && apt upgrade -yq
RUN apt-get install -y --no-install-recommends ocl-icd-opencl-dev ocl-icd-libopencl1 silversearcher-ag vim git curl wget
RUN apt install -y cmake pkg-config libavcodec-dev libavformat-dev libswscale-dev --no-install-recommends

RUN pip install pyopencl
RUN mkdir -p /etc/OpenCL/vendors &&  echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd

RUN cd /tmp/ && wget -qO- https://github.com/opencv/opencv/archive/4.1.2.tar.gz         | tar --transform 's/^dbt2-0.37.50.3/dbt2/' -xz
RUN cd /tmp/ && wget -qO- https://github.com/opencv/opencv_contrib/archive/4.1.2.tar.gz | tar --transform 's/^dbt2-0.37.50.3/dbt2/' -xz
RUN mkdir /tmp/opencv-4.1.2/build && cd /tmp/opencv-4.1.2/build && cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_CUDA=ON -D WITH_OPENCL=ON -D ENABLE_FAST_MATH=1 -D CUDA_FAST_MATH=1 -D WITH_CUBLAS=1 -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-4.1.2/modules -D WITH_LIBV4L=OFF -D WITH_V4L=OFF -D INSTALL_C_EXAMPLES=OFF -D WITH_DC1394=OFF -D ENABLE_NEON=OFF -D OPENCV_ENABLE_NONFREE=ON  -D WITH_PROTOBUF=OFF -D INSTALL_PYTHON_EXAMPLES=ON -D BUILD_OPENCV_PYTHON3=yes  -D PYTHON3_EXECUTABLE=$(which python3) -D PYTHON_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") -D PYTHON_INCLUDE_DIR2=$(python3 -c "from os.path import dirname; from distutils.sysconfig import get_config_h_filename; print(dirname(get_config_h_filename()))") -D PYTHON_LIBRARY=$(python3 -c "from distutils.sysconfig import get_config_var;from os.path import dirname,join ; print(join(dirname(get_config_var('LIBPC')),get_config_var('LDLIBRARY')))") -D PYTHON3_NUMPY_INCLUDE_DIRS=$(python3 -c "import numpy; print(numpy.get_include())") -D PYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")  .. && make -j$(cat /proc/cpuinfo | grep processor | wc -l)  && make -j$(cat /proc/cpuinfo | grep processor | wc -l) install

#COPY assets/cv.tar.gz /tmp/
#RUN cd /tmp && tar -xvf /tmp/cv.tar.gz && rm /tmp/cv.tar.gz && cd /tmp/cv/opencv-4.1.2/build && make -j6 install
##############################
RUN mkdir -p /etc/jupyter/
COPY config/jupyterhub_config.py /etc/jupyter/jupyterhub_config.py
COPY config/environment.yaml /etc/jupyter/environment.yaml
RUN chmod -R 444 /etc/jupyter

USER $NB_UID

WORKDIR /home/$NB_USER
CMD [ "jupyter lab --config /etc/jupyter/jupyterhub_config.py"]
