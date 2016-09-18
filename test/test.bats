#!/usr/bin/env bats

load test_helper
fixtures test

teardown() {
  docker rmi $BATS_TEST_NAME
}

@test "can build and run test command with no tests" {
  docker build --rm -t $BATS_TEST_NAME "$(fixture no-tests)"

  run docker run --rm $BATS_TEST_NAME test
  echo $output
  [ "$status" -eq 0 ]
  #[ "${lines[0]}" = "> no-tests@1.0.0 test /usr/src/app" ]
  #[ "${lines[1]}" = "> echo \"Error: no test specified\"" ]
  #[ "${lines[2]}" = "Error: no test specified" ]
}

@test "can build and run test command with failing test" {
  docker build --rm -t $BATS_TEST_NAME "$(fixture failing-test)"

  run docker run --rm $BATS_TEST_NAME test
  echo $output
  [ "$status" -eq 1 ]
  #[ "${lines[0]}" = "> failing-test@1.0.0 test /usr/src/app" ]
  #[ "${lines[1]}" = "> exit 1" ]
}

@test "can build and run test command with successful test" {
  docker build --rm -t $BATS_TEST_NAME "$(fixture ok-test)"

  run docker run --rm $BATS_TEST_NAME test
  echo $output
  [ "$status" -eq 0 ]
  #[ "${lines[0]}" = "> ok-test@1.0.0 test /usr/src/app" ]
  #[ "${lines[1]}" = "> exit 0" ]
}

@test "can build and run test command with successful test of bower version" {
  docker build --rm -t $BATS_TEST_NAME "$(fixture ok-bower-test)"

  run docker run --rm $BATS_TEST_NAME test
  echo $output
  [ "$status" -eq 0 ]
  #[ "${lines[0]}" = "> ok-bower-test@1.0.0 test /usr/src/app" ]
  #[ "${lines[1]}" = "> exit 0" ]
}
