FROM alpine:3.20
RUN printf '%s\n' '#!/bin/sh' 'echo payments service ready' > /usr/local/bin/payments-service && chmod +x /usr/local/bin/payments-service
ENTRYPOINT ["/usr/local/bin/payments-service"]
