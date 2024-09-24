FROM klakegg/hugo:ext-alpine
WORKDIR ./
COPY . .
CMD ["hugo", "server", "--bind", "0.0.0.0", "--port", "1313", "--watch"]
