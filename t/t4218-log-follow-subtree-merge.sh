#!/bin/sh

test_description='Test --follow follows renames across subtree merges'

GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=master
export GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME

. ./test-lib.sh

test_expect_success 'setup subtree-merged repository' '
	git init inner &&
	echo inner >inner/inner.txt &&
	git -C inner add inner.txt &&
	git -C inner commit -m "inner init" &&

	git init outer &&
	echo outer >outer/outer.txt &&
	git -C outer add outer.txt &&
	git -C outer commit -m "outer init" &&

	git -C outer fetch ../inner master &&
	git -C outer merge -s ours --no-commit --allow-unrelated-histories \
		FETCH_HEAD &&
	git -C outer read-tree --prefix=inner/ -u FETCH_HEAD &&
	git -C outer commit -m "Merge inner repo into inner/ subdirectory"
'

test_expect_success '--follow finds the pre-merge commit through a subtree merge' '
	git -C outer log --follow --pretty=tformat:%s inner/inner.txt >actual &&
	echo "inner init" >expect &&
	test_cmp expect actual
'

test_done
