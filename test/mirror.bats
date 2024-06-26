#!/usr/bin/env bats

load test_helper
export NODE_BUILD_SKIP_MIRROR=
export NODE_BUILD_CACHE_PATH=
export NODE_BUILD_MIRROR_URL=http://mirror.example.com
# TODO move into tests so mirror_cmd doesn't need stubbed in _every_ test
export NODE_BUILD_MIRROR_CMD=mirror_stub


@test "package URL without checksum bypasses mirror" {
  stub curl "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"

  install_fixture definitions/without-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
}


@test "package URL with checksum but no shasum support bypasses mirror" {
  stub shasum false
  stub curl "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"

  install_fixture definitions/with-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub curl
  unstub shasum
}


@test "package URL with checksum hits mirror first" {
  local checksum="ba988b1bb4250dee0b9dd3d4d722f9c64b2bacfc805d1b6eba7426bda72dd3c5"
  local mirror_url="${NODE_BUILD_MIRROR_URL}/$checksum"

  stub shasum true "echo $checksum"
  stub curl "-q -o * -*S* $mirror_url : cp $FIXTURE_ROOT/package-1.0.0.tar.gz \$3"
  stub mirror_stub ": echo $mirror_url"

  install_fixture definitions/with-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub mirror_stub
  unstub curl
  unstub shasum
}


@test "package is fetched from original URL if mirror download fails" {
  local checksum="ba988b1bb4250dee0b9dd3d4d722f9c64b2bacfc805d1b6eba7426bda72dd3c5"
  local mirror_url="${NODE_BUILD_MIRROR_URL}/$checksum"

  stub shasum true "echo $checksum"
  stub curl "-q -o * -*S* $mirror_url : false"\
            "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"
  stub mirror_stub ": echo $mirror_url"

  install_fixture definitions/with-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub mirror_stub
  unstub curl
  unstub shasum
}


@test "package is fetched from original URL if mirror download checksum is invalid" {
  local checksum="ba988b1bb4250dee0b9dd3d4d722f9c64b2bacfc805d1b6eba7426bda72dd3c5"
  local mirror_url="${NODE_BUILD_MIRROR_URL}/$checksum"

  stub shasum true "echo invalid" "echo $checksum"
  stub curl "-q -o * -*S* $mirror_url : cp $FIXTURE_ROOT/package-1.0.0.tar.gz \$3" \
    "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"
  stub mirror_stub ": echo $mirror_url"

  install_fixture definitions/with-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub mirror_stub
  unstub curl
  unstub shasum
}


@test "package is fetched from complete mirror URL" {
  export NODE_BUILD_MIRROR_URL=
  export NODE_BUILD_MIRROR_PACKAGE_URL=http://mirror.example.com/package-1.0.0.tar.gz
  local checksum="ba988b1bb4250dee0b9dd3d4d722f9c64b2bacfc805d1b6eba7426bda72dd3c5"

  stub shasum true "echo $checksum"
  stub curl "-q -o * -*S* $NODE_BUILD_MIRROR_PACKAGE_URL : cp $FIXTURE_ROOT/package-1.0.0.tar.gz \$3"
  stub mirror_stub ": echo $NODE_BUILD_MIRROR_PACKAGE_URL"

  install_fixture definitions/with-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub mirror_stub
  unstub curl
  unstub shasum
}


@test "package is fetched from original URL if complete mirror URL download fails" {
  export NODE_BUILD_MIRROR_URL=
  export NODE_BUILD_MIRROR_PACKAGE_URL=http://mirror.example.com/package-1.0.0.tar.gz
  local checksum="ba988b1bb4250dee0b9dd3d4d722f9c64b2bacfc805d1b6eba7426bda72dd3c5"

  stub shasum true "echo $checksum"
  stub curl "-q -o * -*S* $NODE_BUILD_MIRROR_PACKAGE_URL : false" \
    "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"
  stub mirror_stub ": echo $NODE_BUILD_MIRROR_PACKAGE_URL"

  install_fixture definitions/with-checksum

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub mirror_stub
  unstub curl
  unstub shasum
}


@test "package is fetched from original URL if complete mirror URL download checksum is invalid" {
  export NODE_BUILD_MIRROR_URL=
  export NODE_BUILD_MIRROR_PACKAGE_URL=http://mirror.example.com/package-1.0.0.tar.gz
  local checksum="ba988b1bb4250dee0b9dd3d4d722f9c64b2bacfc805d1b6eba7426bda72dd3c5"

  stub shasum true "echo invalid" "echo $checksum"
  stub curl "-q -o * -*S* $NODE_BUILD_MIRROR_PACKAGE_URL : cp $FIXTURE_ROOT/package-1.0.0.tar.gz \$3" \
    "-q -o * -*S* http://example.com/* : cp $FIXTURE_ROOT/\${5##*/} \$3"
  stub mirror_stub ": echo $NODE_BUILD_MIRROR_PACKAGE_URL"

  install_fixture definitions/with-checksum
  echo "$output" >&2

  assert_success
  assert [ -x "${INSTALL_ROOT}/bin/package" ]

  unstub mirror_stub
  unstub curl
  unstub shasum
}

@test "package is fetched from mirror URL constructed from MIRROR_CMD" {
  skip "TODO: test this scenario"
}
