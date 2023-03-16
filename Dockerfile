FROM rocker/geospatial
RUN install2.r --error --skipinstalled \
	data.tree \
	zoo \
	patchwork \
	SimilarityMeasures \
	plotly
RUN apt-get -y update
RUN apt-get -y install ghp-import
RUN apt-get install gdal-bin
RUN install2.r --error --skipinstalled \
	janitor \
	ragg \
	ggtext \
	ggridges \
	microbenchmark \
	cowplot
RUN wget https://download.osgeo.org/proj/proj-datumgrid-europe-1.5.zip 
RUN sudo unzip proj-datumgrid-europe-1.5 -d /usr/share/proj/
RUN install2.r --error --skipinstalled magick here
RUN install2.r --error --skipinstalled dm
RUN install2.r --error --skipinstalled networkD3
RUN install2.r --error --skipinstalled networkD3 ggrepel geomtextpath

RUN install2.r --error --skipinstalled targets tarchetypes kableExtra

RUN mkdir elsevier; cd elsevier; quarto use template quarto-journals/elsevier --no-prompt; quarto render elsevier.qmd; cd ..; rm -r elsevier

RUN install2.r --error --skipinstalled languageserver httpgd

RUN apt-get update && apt-get install -y \
    python3-pip
RUN pip install shinylive --upgrade
RUN wget https://github.com/quarto-dev/quarto-cli/releases/download/v1.2.269/quarto-1.2.269-linux-amd64.deb
RUN sudo apt install ./quarto-1.2.269-linux-amd64.deb 
RUN quarto install extension quarto-ext/shinylive --no-prompt
RUN pip install matplotlib
RUN pip install numpy
RUN pip install pandas
RUN python3 -m pip install jupyter
RUN python3 -m pip install plotly

RUN install2.r --error --skipinstalled mapedit leaflet.extras microbenchmark
# build this image with the following command
# docker build -f Dockerfile-sandbox -t sandbox .

# note the trailing period
# note the lack of sudo
