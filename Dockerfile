# Use a Ruby base image
FROM ruby:3.2

# Set the working directory
WORKDIR /app

# Copy the Gemfile and Gemfile.lock to the container
COPY Gemfile Gemfile.lock ./

# Install dependencies using Bundler
RUN gem install bundler && bundle install

# Copy the application code to the container
COPY . .

# Expose the port that the web service will run on
EXPOSE 9292

# Start the web service
CMD ["bundle", "exec", "puma", "-w", "2", "-t", "8:32", "-e", "production"]
