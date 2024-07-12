#!/bin/bash

PREFIX="$1"

npm install --save-dev \
  semantic-release \
  @semantic-release/commit-analyzer \
  @semantic-release/changelog \
  @semantic-release/release-notes-generator \
  @semantic-release/git \
  @semantic-release/github \
  @semantic-release/exec

npx semantic-release --tag-format "${PREFIX}\${version}"

# 기존에 사용하던 @semantic-release/exec 의 아래 명령어가 동작안함
# echo \"RELEASE_VERSION=${nextRelease.version}\" >> $GITHUB_ENV
# 따라서 .VERSION 파일로 저장해서 파일 존재 여부와 버전 문자열을 확인

# semantic-release 에서 버전 생성이 안되었을 경우 수동으로 생성
if [[ ! -f .VERSION ]]; then
  echo "semantic release 실패"
  # 마지막 릴리즈 버전을 가져옴
  RELEASE_VERSION=$(gh release list -L 1 --exclude-drafts | cut -f 1)
  # extra 버전 번호 초기화
  EXTRA=0
  # 프리릴리즈 여부 - semantic-release 에서 생성이 안되면 기존적으로 프리릴리즈로 생성
  IS_PRERELEASE=true

  # 버전이 없을 경우 0.0.1 로 설정 - 최초 릴리즈라면 정식릴리즈로 생성
  if [[ -z $RELEASE_VERSION ]]; then
    RELEASE_VERSION='0.0.1'
    IS_PRERELEASE=false
  # 가져온 버전의 패턴 확인
  elif [[ "$RELEASE_VERSION" =~ [0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # 버전 숫자 앞에 붙은 prefix를 제거하고 숫자만 추출 (v1.1.0 -> 1.1.0)
    RELEASE_VERSION=$(echo $RELEASE_VERSION | awk '{ gsub(/[^0-9]+/,"."); print }' | cut -c2-)
    # extra 버전 번호까지 있다면 extra를 분리
    if [[ "$RELEASE_VERSION" =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      EXTRA=$(echo "$RELEASE_VERSION" | cut -f4- -d'.')
      RELEASE_VERSION=$(echo "$RELEASE_VERSION" | cut -f1-3 -d'.')
    fi
  fi

  # release
  if [[ $IS_PRERELEASE == true ]]; then
    # 프리릴리즈라면 EXTRA를 증가시킴
    RELEASE_VERSION=$(echo "$RELEASE_VERSION.$(($EXTRA + 1))")
    # 새 버전 문자열 생성
    RELEASE_VERSION_TAG=$(echo "${PREFIX}${RELEASE_VERSION}")
    gh release create ${RELEASE_VERSION_TAG} --prerelease -t ${RELEASE_VERSION_TAG}
  else
    # 새 버전 문자열 생성
    RELEASE_VERSION_TAG=$(echo "${PREFIX}${RELEASE_VERSION}")
    gh release create ${RELEASE_VERSION_TAG} -t ${RELEASE_VERSION_TAG}
  fi
else
  echo "semantic release 성공"
  RELEASE_VERSION=$(cat .VERSION)
  RELEASE_VERSION_TAG=$(echo "${PREFIX}${RELEASE_VERSION}")
fi
echo "version=$RELEASE_VERSION" >> $GITHUB_OUTPUT
echo "tag=$RELEASE_VERSION_TAG" >> $GITHUB_OUTPUT
