# Stage 1: Build
FROM amazonlinux:2 AS build

LABEL Maintainer="InspectorGadget <@GitHub: InspectorGadget>"

VOLUME /var/www/html

# Set the working directory
WORKDIR /var/www/html/wordpress

# Install necessary packages
RUN yum install -y amazon-linux-extras \
    && amazon-linux-extras enable php8.1 \
    && yum clean metadata \
    && yum install -y php php-fpm mysql httpd zip unzip tar curl php-mysqli wget

# Download and extract WordPress
RUN curl -Ok https://wordpress.org/latest.tar.gz \
    && tar -xzf latest.tar.gz -C /var/www/html \
    && rm latest.tar.gz

# Update permissions for Apache
RUN chown -R apache:apache /var/www/html \
    && chmod -R 755 /var/www/html

# Configure Apache to work with PHP-FPM
RUN sed -i.bak -e 's/AllowOverride None/AllowOverride All/g' /etc/httpd/conf/httpd.conf

# Configure PHP-FPM
RUN sed -i -e 's/^listen = .*/listen = 127.0.0.1:9000/' /etc/php-fpm.d/www.conf

# Copy wpstatic.sh
RUN wget https://us-west-2-aws-training.s3.amazonaws.com/courses/spl-39/v4.1.14.prod-c48d9fd0/scripts/wpstatic.sh --no-check-certificate;

# Change file permission of wpstatic.sh
RUN chmod +x wpstatic.sh
RUN chown -R apache:apache /var/www/html/wordpress

# Stage 2: Runtime
FROM amazonlinux:2 AS runtime

# Set the working directory
WORKDIR /var/www/html/wordpress

# Install necessary packages
RUN yum install -y amazon-linux-extras \
    && amazon-linux-extras enable php8.1 \
    && yum clean metadata \
    && yum install -y php php-fpm mysql httpd php-mysqli zip wget

# Copy the built files from the build stage
COPY --from=build /var/www/html /var/www/html

# Expose port 80 for HTTP
EXPOSE 80

# Start both Apache and PHP-FPM together
CMD ["/bin/sh", "-c", "/usr/sbin/php-fpm -D && /usr/sbin/httpd -D FOREGROUND"]
