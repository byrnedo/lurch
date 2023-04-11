.PHONY: build push
	
IMAGE_VERSION = $(shell echo $${CI_BUILD_REF_NAME:=latest})

build:
	docker build --pull -t byrnedo/lurch:$(IMAGE_VERSION) .

push: 
	docker push  byrnedo/lurch:$(IMAGE_VERSION)


