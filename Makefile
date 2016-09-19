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
node_latest_major := $(call nodeMajorVersion,$(node_latest_version))
node_lts_major := $(call nodeMajorVersion,$(node_lts_version))
node_old_versions := $(filter-out $(node_latest_major) $(node_lts_major),$(node_versions))
tests := $(basename $(notdir $(wildcard test/*.bats)))

.PHONY: build test clean default

default: build test
build: build-latest build-lts $(foreach php,$(php_versions),build-$(php)-latest build-$(php)-lts build-$(php)-old)
test: test-all-latest test-all-lts $(foreach php,$(php_versions),test-all-$(php)-latest test-all-$(php)-lts test-all-$(php)-old)
push: push-latest push-lts $(foreach php,$(php_versions),push-$(php)-latest push-$(php)-lts push-$(php)-old)
clean:
	rm -rf dist test/tmp

dist:
	mkdir -p dist

README.md: README.header.md README.footer.md $(wildcard dist/v*)
	cp README.header.md README.md
	$(MAKE) $(foreach version,$(notdir $(wildcard dist/v*)),README.md-$(version))
	cat README.footer.md >> README.md

README.md-%:
	echo '- [$(shell uniq dist/$*/images.txt | sort | sed -E 's/(.+)/`\1`/' | tr '\n' , | sed -E 's/,/, /g') (*Dockerfile*)](https://github.com/umweltdk/docker-php/blob/master/Dockerfile)' >> README.md
	echo '- [$(shell uniq dist/$*/images-onbuild.txt | sort | sed -E 's/(.+)/`\1`/' | tr '\n' , | sed -E 's/,/, /g') (*Dockerfile.onbuild*)](https://github.com/umweltdk/docker-php/blob/master/Dockerfile.onbuild)' >> README.md
	echo '- [$(shell uniq dist/$*/images-onbuild-bower.txt | sort | sed -E 's/(.+)/`\1`/' | tr '\n' , | sed -E 's/,/, /g') (*Dockerfile.onbuild-bower*)](https://github.com/umweltdk/docker-php/blob/master/Dockerfile.onbuild-bower)' >> README.md


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


build-latest: build-$(php_latest_version)-$(node_latest_version) | dist
	mkdir -p dist/v$(php_latest_version)-$(node_latest_version)
	echo latest >> dist/v$(php_latest_version)-$(node_latest_version)/images.txt
	echo onbuild >> dist/v$(php_latest_version)-$(node_latest_version)/images-onbuild.txt
	echo onbuild-bower >> dist/v$(php_latest_version)-$(node_latest_version)/images-onbuild-bower.txt
	docker tag $(image):$(php_latest_version)-$(node_latest_version) $(image):latest
	docker tag $(image):$(php_latest_version)-$(node_latest_version)-onbuild $(image):onbuild
	docker tag $(image):$(php_latest_version)-$(node_latest_version)-onbuild-bower $(image):onbuild-bower

build-lts: build-$(php_lts_version)-$(node_lts_version) | dist
	mkdir -p dist/v$(php_lts_version)-$(node_lts_version)
	echo lts >> dist/v$(php_lts_version)-$(node_lts_version)/images.txt
	echo lts-onbuild >> dist/v$(php_lts_version)-$(node_lts_version)/images-onbuild.txt
	echo lts-onbuild-bower >> dist/v$(php_lts_version)-$(node_lts_version)/images-onbuild-bower.txt
	docker tag $(image):$(php_lts_version)-$(node_lts_version) $(image):lts
	docker tag $(image):$(php_lts_version)-$(node_lts_version)-onbuild $(image):lts-onbuild
	docker tag $(image):$(php_lts_version)-$(node_lts_version)-onbuild-bower $(image):lts-onbuild-bower

$(foreach php,$(php_versions),build-$(php)-latest): | dist
	$(MAKE) build-$(call phpVersion,$(subst build-,,$@))-$(node_latest_version)
	$(MAKE) build-$(call phpVersion,$(subst build-,,$@))-$(node_latest_major)
	mkdir -p dist/v$(call phpVersion,$(subst build-,,$@))-$(node_latest_version)
	echo $(call phpVersion,$(subst build-,,$@))-latest >> dist/v$(call phpVersion,$(subst build-,,$@))-$(node_latest_version)/images.txt
	echo $(call phpVersion,$(subst build-,,$@))-latest-onbuild >> dist/v$(call phpVersion,$(subst build-,,$@))-$(node_latest_version)/images-onbuild.txt
	echo $(call phpVersion,$(subst build-,,$@))-latest-onbuild-bower >> dist/v$(call phpVersion,$(subst build-,,$@))-$(node_latest_version)/images-onbuild-bower.txt
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(node_latest_version) $(image):$(call phpVersion,$(subst build-,,$@))-latest
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(node_latest_version)-onbuild $(image):$(call phpVersion,$(subst build-,,$@))-latest-onbuild
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(node_latest_version)-onbuild-bower $(image):$(call phpVersion,$(subst build-,,$@))-latest-onbuild-bower

$(foreach php,$(php_versions),build-$(php)-lts): | dist
	$(MAKE) build-$(call phpVersion,$(subst build-,,$@))-$(node_lts_version)
	$(MAKE) build-$(call phpVersion,$(subst build-,,$@))-$(node_lts_major)
	mkdir -p dist/v$(call phpVersion,$(subst build-,,$@))-$(node_lts_version)
	echo $(call phpVersion,$(subst build-,,$@))-lts >> dist/v$(call phpVersion,$(subst build-,,$@))-$(node_lts_version)/images.txt
	echo $(call phpVersion,$(subst build-,,$@))-lts-onbuild >> dist/v$(call phpVersion,$(subst build-,,$@))-$(node_lts_version)/images-onbuild.txt
	echo $(call phpVersion,$(subst build-,,$@))-lts-onbuild-bower >> dist/v$(call phpVersion,$(subst build-,,$@))-$(node_lts_version)/images-onbuild-bower.txt
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(node_lts_version) $(image):$(call phpVersion,$(subst build-,,$@))-lts
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(node_lts_version)-onbuild $(image):$(call phpVersion,$(subst build-,,$@))-lts-onbuild
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(node_lts_version)-onbuild-bower $(image):$(call phpVersion,$(subst build-,,$@))-lts-onbuild-bower

$(foreach php,$(php_versions),build-$(php)-old):
	$(MAKE) $(foreach node,$(node_old_versions),build-$(call phpVersion,$(subst build-,,$@))-$(node))

$(foreach node,$(node_versions),$(foreach php,$(php_versions),build-$(php)-$(node))): | dist
	$(MAKE) build-$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))
	mkdir -p dist/v$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))
	echo $(call phpVersion,$(subst build-,,$@))-$(call nodeVersion,$(subst build-,,$@)) >> dist/v$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))/images.txt
	echo $(call phpVersion,$(subst build-,,$@))-$(call nodeVersion,$(subst build-,,$@))-onbuild >> dist/v$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))/images-onbuild.txt
	echo $(call phpVersion,$(subst build-,,$@))-$(call nodeVersion,$(subst build-,,$@))-onbuild-bower >> dist/v$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))/images-onbuild-bower.txt
	mkdir -p dist/v$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))
	echo $(call phpVersion,$(subst build-,,$@))-$(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))))) >> dist/v$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))/images.txt
	echo $(call phpVersion,$(subst build-,,$@))-$(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@))))))-onbuild >> dist/v$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))/images-onbuild.txt
	echo $(call phpVersion,$(subst build-,,$@))-$(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@))))))-onbuild-bower >> dist/v$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))/images-onbuild-bower.txt
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@))) $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeVersion,$(subst build-,,$@))
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))-onbuild $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeVersion,$(subst build-,,$@))-onbuild
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))-onbuild-bower $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeVersion,$(subst build-,,$@))-onbuild-bower
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@))) $(image):$(call phpVersion,$(subst build-,,$@))-$(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@))))))
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))-onbuild $(image):$(call phpVersion,$(subst build-,,$@))-$(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@))))))-onbuild
	docker tag $(image):$(call phpVersion,$(subst build-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@)))-onbuild-bower $(image):$(call phpVersion,$(subst build-,,$@))-$(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(call nodeFullVersion,$(call nodeVersion,$(subst build-,,$@))))))-onbuild-bower

build-%: dist/Dockerfile.base.% dist/Dockerfile.onbuild.% dist/Dockerfile.onbuild-bower.%
	mkdir -p dist/v$*
	echo $* >> dist/v$*/images.txt
	echo $*-onbuild >> dist/v$*/images-onbuild.txt
	echo $*-onbuild-bower >> dist/v$*/images-onbuild-bower.txt
	docker build --pull -t $(image):$* -f dist/Dockerfile.base.$* .
	docker build -t $(image):$(if $(subst latest,,$*),$*-,)onbuild -f dist/Dockerfile.onbuild.$* .
	docker build -t $(image):$(if $(subst latest,,$*),$*-,)onbuild-bower -f dist/Dockerfile.onbuild-bower.$* .

$(foreach php,$(php_versions),push-$(php)-latest):
	$(MAKE) real-push-$(call phpVersion,$(subst push-,,$@))-latest
	$(MAKE) push-$(call phpVersion,$(subst push-,,$@))-$(node_latest_version)
	$(MAKE) push-$(call phpVersion,$(subst push-,,$@))-$(node_latest_major)

$(foreach php,$(php_versions),push-$(php)-lts):
	$(MAKE) real-push-$(call phpVersion,$(subst push-,,$@))-lts
	$(MAKE) push-$(call phpVersion,$(subst push-,,$@))-$(node_lts_version)
	$(MAKE) push-$(call phpVersion,$(subst push-,,$@))-$(node_lts_major)

$(foreach php,$(php_versions),push-$(php)-old):
	$(MAKE) $(foreach node,$(node_old_versions),push-$(call phpVersion,$(subst push-,,$@))-$(node))

$(foreach node,$(node_versions),$(foreach php,$(php_versions),push-$(php)-$(node))):
	$(MAKE) real-push-$(call phpVersion,$(subst push-,,$@))-$(call nodeVersion,$(subst push-,,$@))
	$(MAKE) push-$(call phpVersion,$(subst push-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst push-,,$@)))
	[[ "$(call nodeVersion,$(subst push-,,$@))" == "0.12" ]] || $(MAKE) push-$(call phpVersion,$(subst push-,,$@))-$(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(call nodeFullVersion,$(call nodeVersion,$(subst push-,,$@))))))

push-%: 
	$(MAKE) real-push-$*

real-push-%:
	docker push $(image):$*
	docker push $(image):$(if $(subst latest,,$*),$*-,)onbuild
	docker push $(image):$(if $(subst latest,,$*),$*-,)onbuild-bower

$(foreach php,$(php_versions),test-all-$(php)-latest):
	$(MAKE) real-test-all-$(call phpVersion,$(subst test-all-,,$@))-latest
	$(MAKE) test-all-$(call phpVersion,$(subst test-all-,,$@))-$(node_latest_version)
	$(MAKE) test-all-$(call phpVersion,$(subst test-all-,,$@))-$(node_latest_major)

$(foreach php,$(php_versions),test-all-$(php)-lts):
	$(MAKE) real-test-all-$(call phpVersion,$(subst test-all-,,$@))-lts
	$(MAKE) test-all-$(call phpVersion,$(subst test-all-,,$@))-$(node_lts_version)
	$(MAKE) test-all-$(call phpVersion,$(subst test-all-,,$@))-$(node_lts_major)

$(foreach php,$(php_versions),test-all-$(php)-old):
	$(MAKE) $(foreach node,$(node_old_versions),test-all-$(call phpVersion,$(subst test-all-,,$@))-$(node))

$(foreach node,$(node_versions),$(foreach php,$(php_versions),test-all-$(php)-$(node))):
	$(MAKE) real-test-all-$(call phpVersion,$(subst test-all-,,$@))-$(call nodeVersion,$(subst test-all-,,$@))
	$(MAKE) test-all-$(call phpVersion,$(subst test-all-,,$@))-$(call nodeFullVersion,$(call nodeVersion,$(subst test-all-,,$@)))
	[[ "$(call nodeVersion,$(subst test-all-,,$@))" == "0.12" ]] || $(MAKE) test-all-$(call phpVersion,$(subst test-all-,,$@))-$(subst $(space),.,$(wordlist 1,2,$(subst ., ,$(call nodeFullVersion,$(call nodeVersion,$(subst test-all-,,$@))))))

test-all-%:
	$(MAKE) real-test-all-$*

real-test-all-%:
	IMAGE_VERSION=$* bats/bin/bats test/*.bats

$(foreach test,$(tests),run-test-$(test)-%):
	IMAGE_VERSION=$* bats/bin/bats test/$(subst -$*,,$(subst run-test-,,$@)).bats
