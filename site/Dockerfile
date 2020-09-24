FROM node:14.9-slim

RUN mkdir /work/
WORKDIR /work/

COPY ./src/package.json /work/package.json
RUN npm install

COPY ./src/ /work/

CMD node .
