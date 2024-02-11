all:
	cd home; stow --verbose --target=$${HOME} --restow */

delete:
	cd home; stow --verbose --target=$${HOME} --delete */
