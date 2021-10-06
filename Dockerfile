FROM fedora:34

# install dependencies
RUN dnf install -y dnf-plugins-core wget gpg git make gcc efitools
RUN dnf builddep -y shim-unsigned-x64

# setup our git environment
ARG GIT_COMMITTER_DATE="Tue, 29 Jun 2021 00:00:00 +0000"
RUN git config --global user.name "Shim Builder" && \
	git config --global user.email "guest@guest.org"

# clone the git repo
RUN git clone https://github.com/rhboot/shim shim

# copy our build configuration, certs, and gpg keys
COPY config/* /shim/
COPY config/certs /shim/certs
COPY config/gpg /shim/gpg

# import the gpg key(s) used to sign the release tag
RUN gpg --trust-model always --import /shim/gpg/*.asc

# create a build branch
# NOTE: use tag '15.4' as the base and point upstream to the shim-15.4 branch
RUN cd shim; \
	git checkout -b build -t origin/shim-15.4 && \
	git verify-tag 15.4 && \
	git reset --hard 15.4 && \
	git submodule update --init --recursive

# apply patches
RUN cd shim; git cherry-pick 16eeafe28c552bca36953d75581500887631a7f1
RUN cd shim; git cherry-pick 822d07ad4f07ef66fe447a130e1027c88d02a394
RUN cd shim; git cherry-pick 5b3ca0d2f7b5f425ba1a14db8ce98b8d95a2f89f
RUN cd shim; git cherry-pick 4068fd42c891ea6ebdec056f461babc6e4048844
RUN cd shim; git cherry-pick 493bd940e5c6e28e673034687de7adef9529efff
RUN cd shim; git cherry-pick 05875f3aed1c90fe071c66de05744ca2bcbc2b9e
RUN cd shim; git cherry-pick 9f973e4e95b1136b8c98051dbbdb1773072cc998
RUN cd shim; git cherry-pick 4d64389c6c941d21548b06423b8131c872e3c3c7
RUN cd shim; git cherry-pick 7501b6bb449f6e4d13e700a65650f9308f54c8c1
RUN cd shim; git cherry-pick 4583db41ea58195956d4cdf97c43a195939f906b

# generate the vendor_db.esl file from certs
RUN cd shim/certs; \
	for i in *.pem; do \
		sha1sum $i; \
		openssl x509 -text -noout -in $i; \
		cert=`echo $i | sed 's/\..*//'`; \
		cert-to-efi-sig-list -g $cert.guid $i $cert.esl; \
	done; \
	cat *.esl > /shim/vendor_db.esl; \
	ls -l *.esl /shim/vendor_db.esl

# append our sbat data to the upstream data/sbat.csv
RUN cd shim; cat sbat.csv >> data/sbat.csv && cat data/sbat.csv

# OPTIONAL: make a snapshot of the sources we are building
#RUN tar zcf shim-src_snapshot.tar.gz shim/

# OPTIONAL: make a log of the commits on top of the release tag
RUN cd shim; git log -p 15.4..HEAD > shim-git_commit_extra.log

# do the build
RUN cd shim; make

# output the sha256 checksums of the *.efi binaries
RUN cd shim; sha256sum *.efi
