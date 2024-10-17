FROM alpine:latest AS builder

RUN apk add --no-cache wget tar

RUN wget https://github.com/gohugoio/hugo/releases/download/v0.134.3/hugo_extended_0.134.3_linux-arm64.tar.gz \
	&& tar -zxvf hugo_extended_0.134.3_linux-arm64.tar.gz

FROM alpine:latest

RUN apk add --no-cache libc6-compat libstdc++ libgcc git

COPY --from=builder /hugo /usr/bin/hugo

WORKDIR /app

COPY . .

RUN chmod +x ./start.sh

CMD ["./start.sh"]
