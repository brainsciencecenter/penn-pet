FROM python:3.9-slim-buster as base

ENV FLYWHEEL=/flywheel/v0
ENV PYTHONPATH=/flywheel/v0/QuANTs/python/quants/quants

WORKDIR ${FLYWHEEL}

RUN apt-get update
RUN apt-get install git -y
RUN python3 -m pip install --upgrade pip

COPY requirements.txt ${FLYWHEEL}

RUN pip install -r requirements.txt
RUN git clone https://github.com/ftdc-picsl/QuANTs.git

COPY atlases ${FLYWHEEL}/atlases/
COPY bsub_pet_quants.sh lpc_lstat.R pet_proc_bids.sh run_sfsrr.sh submit_pet_proc_bids.sh T_template0.nii.gz ${FLYWHEEL}/

COPY pet_quants.py run run_pet_quants.sh ${FLYWHEEL}/
RUN chmod +x run


ENTRYPOINT ["./run"]
