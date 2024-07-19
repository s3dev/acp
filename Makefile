#
# Makefile for the acp project.
#
# Optional parameters:
#
#   dst: Path to the deployment directory. Defaults to /usr/local/bin.
#

ifndef dst
    dst=/usr/local/bin
    dst_acpd=$(dst)/acp.d
else
    dst_acpd="$(dst)"/acp.d
endif

all: clean install

install:
	@echo "\nInstalling to: $(dst_acpd)"
	@if [ ! -d "$(dst_acpd)" ]; then sudo mkdir "$(dst_acpd)"; fi
	sudo cp -r ./bin $(dst_acpd)/bin
	sudo cp -r ./lib $(dst_acpd)/lib
	sudo cp ./README.md $(dst_acpd)
	sudo ln -s $(dst_acpd)/bin/acp.sh $(dst)/acp
	@echo "Done.\n"

clean:
	@if [ -d "$(dst_acpd)" ]; then \
	    echo "\nRemoving old acp installation ..."; \
	    sudo rm -rf $(dst)/acp*; \
	    echo "Done.\n"; \
	fi

