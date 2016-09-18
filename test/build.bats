#!/usr/bin/env bats

load test_helper
fixtures build

@test "fails to build with missing node dependency" {
  ! docker build --rm "$(fixture missing-dependency)"
}

@test "fails to build with missing package.json" {
  ! docker build --rm "$(fixture missing-package-json)"
}

@test "fails to build with failing postinstall" {
  ! docker build --rm "$(fixture failing-postinstall)"
}

@test "fails to build with missing bower dependency" {
  ! docker build --rm "$(fixture missing-bower-dependency)"
}

@test "fails to build with missing bower.json" {
  ! docker build --rm "$(fixture missing-bower-json)"
}

@test "fails to build with failing build script" {
  ! docker build --rm "$(fixture failing-build-script)"
}

@test "succeeds building with postinstall" {
  docker build --rm "$(fixture ok-postinstall)"
}

@test "succeeds in building with missing build script" {
  docker build --rm "$(fixture missing-build-script)"
}

@test "succeeds in building when touching file" {
  docker build --rm "$(fixture touch-file)"
}

@test "fails to build bower version with failing build script" {
  ! docker build --rm "$(fixture failing-bower-build-script)"
}

@test "succeeds in building bower version with missing build script" {
  docker build --rm "$(fixture missing-bower-build-script)"
}
