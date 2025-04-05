FROM kong/kong-gateway:3.10
# Ensure any patching steps are executed as root user
USER root

# Add custom plugin to the image
COPY ./plugins/custom-auth /usr/local/share/lua/5.1/kong/plugins/custom-auth


ENV KONG_PLUGINS=bundled,custom-auth

# Ensure kong user is selected for image execution
USER kong

# Run kong
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 8000 8443 8001 8444
STOPSIGNAL SIGQUIT
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
CMD ["kong", "docker-start"]
