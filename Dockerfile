# Use a lightweight Node.js base image
FROM node:20-alpine

# Set build arguments and environment variables for optimal performance
ARG NODE_ENV=production
ENV NODE_ENV=$NODE_ENV \
    NPM_CONFIG_LOGLEVEL=warn \
    NPM_CONFIG_PROGRESS=false

# Define a non-root user with specific UID and GID for security
ARG USER_NAME=nodejs
ARG USER_UID=1001
ARG USER_GID=1001

# Install essential packages, including tini for better process management
RUN apk add --no-cache tini

# Create a non-root user and group
RUN addgroup -g $USER_GID $USER_NAME && \
    adduser -S -u $USER_UID -G $USER_NAME $USER_NAME

# Set working directory and update ownership for non-root user
WORKDIR /app
RUN chown $USER_NAME:$USER_NAME /app

# Copy package files and install dependencies
COPY --chown=$USER_NAME:$USER_NAME package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy application code with ownership set to non-root user
COPY --chown=$USER_NAME:$USER_NAME . .

# Create a writable temporary directory with specific permissions
RUN mkdir -p /app/tmpdata && chown -R $USER_NAME:$USER_NAME /app/tmpdata

# Switch to non-root user for running the application
USER $USER_NAME

# Expose application port
EXPOSE 3000

# Set entrypoint to tini for signal handling and process management
ENTRYPOINT ["/sbin/tini", "--"]

# Define healthcheck to monitor application without write dependencies
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Start the application
CMD ["npm", "start"]
