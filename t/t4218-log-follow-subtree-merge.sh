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

test_expect_success 'setup merge with rename sources on multiple parents' '
	git init left &&
	printf "shared content\n" >left/a.txt &&
	git -C left add a.txt &&
	git -C left commit -m "left: a.txt" &&

	git init right &&
	printf "shared content\n" >right/b.txt &&
	git -C right add b.txt &&
	git -C right commit -m "right: b.txt" &&

	git -C left fetch ../right master &&
	git -C left merge -s ours --no-commit --allow-unrelated-histories \
		FETCH_HEAD &&
	git -C left rm a.txt &&
	printf "shared content\n" >left/c.txt &&
	git -C left add c.txt &&
	git -C left commit -m "Merge: rename to c.txt" &&

	printf "more content\n" >>left/c.txt &&
	git -C left add c.txt &&
	git -C left commit -m "modify c.txt"
'

test_expect_success '--follow does not switch when multiple parents supply a rename source' '
	git -C left log --follow --pretty=tformat:%s c.txt >actual &&
	echo "modify c.txt" >expect &&
	test_cmp expect actual
'

test_done
