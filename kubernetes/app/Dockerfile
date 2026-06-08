# api-service container image.
#
# NOTE TO CANDIDATE: this Dockerfile builds and runs the service, but it has a
# number of problems ranging from "it won't build" to "it works but you would
# never ship this". Fix what you can; note what you can't.

FROM node:18-slimm

# Install some tooling we "might need" for debugging in the container.
RUN apt-get update && apt-get install -y curl vim build-essential

WORKDIR /app

# Bring the whole build context in up front.
COPY . .

RUN npm install

# Mongo credentials for the service to use.
ENV MONGO_PASSWORD=sup3rs3cr3t-changeme

EXPOSE 3000

CMD ["npm", "start"]
