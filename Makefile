
CURPATH=$(PWD)
TARGET_DIR=$(CURPATH)/_output/bin

TARGET_GOOS=$(shell go env GOOS)
TARGET_GOARCH=$(shell go env GOARCH)

REV=$(shell git describe --long --tags --match='v*' --dirty 2>/dev/null || git rev-list -n1 HEAD)


build-localdisk:
	env CGO_LDFLAGS=/usr/lib64/libstoragemgmt.so GOOS=$(TARGET_GOOS) GOARCH=$(TARGET_GOARCH) go build -mod=vendor -o $(TARGET_DIR)/localdisk .
	echo "Writing binary to: $(TARGET_DIR)/localdisk"
