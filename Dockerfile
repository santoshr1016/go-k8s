FROM golang:alpine as builder
WORKDIR /go/src/github.com/acquia/kaas-sli

RUN apk add --no-cache git

COPY internal internal
COPY pkg pkg
COPY main.go main.go
COPY go.mod go.mod
COPY go.sum go.sum

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o kaas-sli

FROM scratch as final
COPY --from=builder /go/src/github.com/acquia/kaas-sli .
EXPOSE 3001
CMD ["/kaas-sli"]

# Start from the latest golang base image
FROM golang:latest as builder

# Set the Current Working Directory inside the container
WORKDIR /go/src/github.com/santoshr1016/go-k8s

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependancies. Dependencies will be cached if the go.mod and go.sum files are not changed
RUN go mod download

# Copy the source from the current directory to the Working Directory inside the container
COPY . .

# Build the Go app
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .


######## Start a new stage from scratch #######
FROM scratch as final

COPY --from=builder /go/src/github.com/santoshr1016/go-k8s .

# Expose port 8080 to the outside world
EXPOSE 8080

# Command to run the executable
CMD ["./go-k8s"]