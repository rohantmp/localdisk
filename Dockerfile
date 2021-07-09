FROM docker.io/rohantmp/centos-golang-builder AS builder
WORKDIR /go/src/github.com/pcuzner/localdisk
COPY . .
RUN dnf config-manager --set-enabled powertools
RUN yum install -y libstoragemgmt libstoragemgmt-devel
RUN make build-localdisk

FROM centos-base
RUN yum install -y libstoragemgmt

COPY --from=builder /go/src/github.com/pcuzner/localdisk/_output/bin/localdisk /usr/bin/

ENTRYPOINT ["/usr/bin/localdisk"]
