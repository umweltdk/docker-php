image := umweltdk/php
node_versions := 0.12 4 5 6
php_versions := 7.0 5.6
php_latest_version := 7.0
php_lts_version := 5.6
node_latest_version := $(shell curl -sSL --compressed "http://nodejs.org/dist/latest" | grep '<a href="node-v'"$1." | sed -E 's!.*<a href="node-v([0-9.]+)-.*".*!\1!' | head -1)
node_lts_version := $(shell curl -sSL --compressed "https://nodejs.org/en/" | egrep '<a .* title=".* LTS"' | sed -E 's!.*data-version="v([0-9.]+)".*!\1!')

comma:= ,
empty:=
space:= $(empty) $(empty)
nodeFullVersion = $(shell curl -sSL --compressed "http://nodejs.org/dist/latest-v$1.x/" | grep '<a href="node-v'"$1." | sed -E 's!.*<a href="node-v([0-9.]+)-.*".*!\1!' | head -1)
nodeMajorVersion = $(subst $(space),.,$(wordlist 1,$(if $(subst 0,,$(word 1,$(subst ., ,$(1)))),1,2),$(subst ., ,$(1))))
phpVersion = $(firstword $(subst -, ,$(1)))
nodeVersion = $(word 2,$(subst -, ,$(1)))
all_versions := latest 4 5 6 $(node_versions) $(foreach version,$(node_versions),$(call fullVersion,$(version)))
tests := $(basename $(notdir $(wildcard test/*.bats)))

.PHONY: build test clean default

default: build test
build: $(foreach version,$(all_versions),build-$(version))
test: $(foreach version,$(all_versions),test-all-$(version))
push: $(foreach version,$(all_versions),push-$(version))
clean:
	echo $(call nodeMajorVersion,6.5.0)
	echo $(call nodeMajorVersion,0.12.5)
	rm -rf dist test/tmp

dist:
	mkdir -p dist

dist/Dockerfile.base.%: Dockerfile | dist
	cp $< $@.tmp
	sed -E -i.bak 's/^(FROM .+:).*-(.*)/\1$(call phpVersion,$*)-\2/;' "$@.tmp"
	rm "$@.tmp.bak"
	sed -E -i.bak 's/^(ENV NODE_VERSION ).*/\1$(call nodeVersion,$*)/;' "$@.tmp"
	rm "$@.tmp.bak"
	mv $@.tmp $@

dist/Dockerfile.onbuild.%: Dockerfile.onbuild | dist
	cp $< $@.tmp
	sed -E -i.bak 's/^(FROM .+:).*/\1$*/;' "$@.tmp"
	rm "$@.tmp.bak"
	mv $@.tmp $@

dist/Dockerfile.onbuild-bower.%: Dockerfile.onbuild-bower | dist
	cp $< $@.tmp
	sed -E -i.bak 's/^(FROM .+:).*/\1$*/;' "$@.tmp"
	rm "$@.tmp.bak"
	mv $@.tmp $@

build-latest: build-$(php_latest_version)-$(node_latest_version)
	docker tag $(image):$(php_latest_version)-$(node_latest_version) $(image):latest
	docker tag $(image):$(php_latest_version)-$(node_latest_version)-onbuild $(image):onbuild

build-lts: build-$(php_lts_version)-$(node_lts_version)
	docker tag $(image):$(php_lts_version)-$(node_lts_version) $(image):lts
	docker tag $(image):$(php_lts_version)-$(node_lts_version)-onbuild $(image):lts-onbuild

$(foreach php,$(php_versions),build-$(php)-latest)):
	$(MAKE) build-$(call phpVersion,$(subst build-,,$@))-$(node_latest_version)
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(node_latest_version) $(image):$(call phpVersion,$(subst build-,,$@))-latest
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(node_latest_version)-onbuild $(image):$(call phpVersion,$(subst build-,,$@))-latest-onbuild

$(foreach php,$(php_versions),build-$(php)-lts)):
	$(MAKE) build-$(call phpVersion,$(subst build-,,$@))-$(node_lts_version)
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(node_lts_version) $(image):$(call phpVersion,$(subst build-,,$@))-lts
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(node_lts_version)-onbuild $(image):$(call phpVersion,$(subst build-,,$@))-lts-onbuild

$(foreach node,$(node_versions),$(foreach php,$(php_versions),build-$(php)-$(node))):
	$(MAKE) build-$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@))) $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeVersion,$(subst build-,,$@))
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))-onbuild $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeVersion,$(subst build-,,$@))-onbuild
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@))) $(image):$(call phpVersion,$(subst build-,,$@))-$(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@))))))
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))-onbuild $(image):$(call phpVersion,$(subst build-,,$@))-$(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@))))))-onbuild

build-%: dist/Dockerfile.base.% dist/Dockerfile.onbuild.% #dist/Dockerfile.onbuild-bower.%
	docker build --pull -t $(image):$* -f dist/Dockerfile.base.$* .
	docker build -t $(image):$(if $(subst latest,,$*),$*-,)onbuild -f dist/Dockerfile.onbuild.$* .
	#docker build -t $(image):$(if $(subst latest,,$*),$*-,)onbuild-bower -f dist/Dockerfile.onbuild-bower.$* .

push-%:
	docker push $(image):$*
	docker push $(image):$(if $(subst latest,,$*),$*-,)onbuild
	#docker push $(image):$(if $(subst latest,,$*),$*-,)onbuild-bower

test-all-%:
	IMAGE_VERSION=$* bats/bin/bats test/*.bats

$(foreach test,$(tests),run-test-$(test)-%):
	IMAGE_VERSION=$* bats/bin/bats test/$(subst -$*,,$(subst run-test-,,$@)).bats
