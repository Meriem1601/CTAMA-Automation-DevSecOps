# you can find your node version with: node --version
#FROM node:20

# Create app directory
WORKDIR /app

# Install app dependencies
COPY package*.json ./

# Install dependecies
RUN npm install

# Bundle app
COPY . .

# Define your port
EXPOSE 3000

# Tell Docker how to run your app
CMD [ "node", "app.js" ]
