FROM quay.io/centos/centos:stream8 as builder


RUN dnf config-manager --set-enabled powertools

RUN dnf install -y libstoragemgmt libstoragemgmt-devel golang go-toolset make git gcc 
RUN mkdir -p /go && chmod -R 777 /go 

ENV GOPATH=/go \
    BASH_ENV=/opt/rh/go-toolset/enable \
    ENV=/opt/rh/go-toolset/enable \
    PROMPT_COMMAND=". /opt/rh/go-toolset/enable"

WORKDIR /go/src/github.com/pcuzner/localdisk
COPY . . 

RUN make build-localdisk

FROM quay.io/centos/centos:stream8

RUN dnf install -y libstoragemgmt

COPY --from=builder /go/src/github.com/pcuzner/localdisk/_output/bin/localdisk /usr/bin/

ENTRYPOINT ["/usr/bin/localdisk"]


