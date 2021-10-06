This repo is for review of requests for signing shim.  To create a request for review:

- clone this repo
- edit the template below
- add the shim.efi to be signed
- add build logs
- add any additional binaries/certificates/SHA256 hashes that may be needed
- commit all of that
- tag it with a tag of the form "myorg-shim-arch-YYYYMMDD"
- push that to github
- file an issue at https://github.com/rhboot/shim-review/issues with a link to your branch
- approval is ready when you have accepted tag

Note that we really only have experience with using GRUB2 on Linux, so asking
us to endorse anything else for signing is going to require some convincing on
your part.

Here's the template:

-------------------------------------------------------------------------------
What organization or people are asking to have this signed:
-------------------------------------------------------------------------------

> Cisco Systems, Inc.

-------------------------------------------------------------------------------
What product or service is this for:
-------------------------------------------------------------------------------

> PuzzleOS, a Linux based appliance OS used in a number of Cisco products.

-------------------------------------------------------------------------------
What's the justification that this really does need to be signed for the whole world to be able to boot it:
-------------------------------------------------------------------------------

> PuzzleOS is designed to run on any platform that supports UEFI Secure Boot
and the easiest way to support the largest number of systems is to have a shim
bootloader signed by Microsoft.

-------------------------------------------------------------------------------
Who is the primary contact for security updates, etc.
-------------------------------------------------------------------------------
> Name: Serge Hallyn
> Position: Principal Engineer, Cisco
> Email address: shallyn@cisco.com, sergeh@kernel.org
> PGP key, signed by the other security contacts, and preferably also with
  signatures that are reasonably well known in the Linux community:
> 66D0387DB85D320F8408166DB175CFA98F192AF2

-------------------------------------------------------------------------------
Who is the secondary contact for security updates, etc.
-------------------------------------------------------------------------------
> - Name: Tycho Andersen
> - Position: Engineering Technical Leader, Cisco
> - Email address: tycander@cisco.com, tycho@tycho.pizza
> - PGP key, signed by the other security contacts, and preferably also with
  signatures that are reasonably well known in the Linux community:
> 3CCAB226289DE0160C61BDB418D18F1BC464DCA3

-------------------------------------------------------------------------------
Please create your shim binaries starting with the 15.4 shim release tar file:
https://github.com/rhboot/shim/releases/download/15.4/shim-15.4.tar.bz2

This matches https://github.com/rhboot/shim/releases/tag/15.4 and contains
the appropriate gnu-efi source.
-------------------------------------------------------------------------------

> We built our production shim using the same Dockerfile we are including in
our review submission.  The Dockerfile should be self documenting regarding the
base source tree and additional patches, but all of the sources involved in
our shim submission are either part of the 'shim-15.4' branch, the default
branch, or exiting GitHub PRs.  All of the patches we selected were based on
guidance from upstream as well as the Fedora submission from April 2021.

-------------------------------------------------------------------------------
URL for a repo that contains the exact code which was built to get this binary:
-------------------------------------------------------------------------------

> As the base source tree and additional patches can be found in the upstream
repository or PRs we did not create our own repository, we generate the build
branch in the Dockerfile using the signed '15.4' tag as a base.

-------------------------------------------------------------------------------
What patches are being applied and why:
-------------------------------------------------------------------------------
> With respect to the patches we included in our submission we followed
upstream guidance and the Fedora April 2021 submission.  All of the patches
we applied to the base '15.4' tag are listed below; most of these patches have
already been merged into the default shim branch, but some exist only in
outstanding PRs.  The Dockerfile has more information on the patches and their
origin.

```
commit 16eeafe28c552bca36953d75581500887631a7f1
Author: Peter Jones <pjones@redhat.com>
Date:   Wed Mar 31 09:44:53 2021 -0400

    shim-15.4 branch: update .gitmodules to point at shim-15.4 in gnu-efi

    This is purely superficial, as the commit points at the shim-15.4 branch
    already, but some people have found it confusing.

    This fixes issue #356.

    Signed-off-by: Peter Jones <pjones@redhat.com>
```

```
commit 822d07ad4f07ef66fe447a130e1027c88d02a394
Author: Adam Williamson <awilliam@redhat.com>
Date:   Thu Apr 8 22:39:02 2021 -0700

    Fix handling of ignore_db and user_insecure_mode

    In 65be350308783a8ef537246c8ad0545b4e6ad069, import_mok_state() is split
    up into a function that manages the whole mok state, and one that
    handles the state machine for an individual state variable.
    Unfortunately, the code that initializes the global ignore_db and
    user_insecure_mode was copied from import_mok_state() into the new
    import_one_mok_state() function, and thus re-initializes that state each
    time it processes a MoK state variable, before even assessing if that
    variable is set.  As a result, we never honor either flag, and the
    machine owner cannot disable trusting the system firmware's db/dbx
    databases or disable validation altogether.

    This patch removes the extra re-initialization, allowing those variables
    to be set properly.

    Signed-off-by: Adam Williamson <awilliam@redhat.com>
```

```
commit 5b3ca0d2f7b5f425ba1a14db8ce98b8d95a2f89f
Author: Peter Jones <pjones@redhat.com>
Date:   Wed Mar 31 14:54:52 2021 -0400

    Fix a broken file header on ia32

    Commit c6281c6a195edee61185 needs to have included a ". = ALIGN(4096)"
    directive before .reloc, but fails to do so.

    As a result, binutils, which does not care about the actual binary
    format's constraints in any way, does not enforce the section alignment,
    and it will not load.

    Signed-off-by: Peter Jones <pjones@redhat.com>
```

```
commit 4068fd42c891ea6ebdec056f461babc6e4048844
Author: Gary Lin <glin@suse.com>
Date:   Thu Apr 8 16:23:03 2021 +0800

    mok: allocate MOK config table as BootServicesData

    Linux kernel is picky when reserving the memory for x86 and it only
    expects BootServicesData:

    https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/arch/x86/platform/efi/quirks.c?h=v5.11#n254

    Otherwise, the following error would show during system boot:

    Apr 07 12:31:56.743925 localhost kernel: efi: Failed to lookup EFI memory descriptor for 0x000000003dcf8000

    Although BootServicesData would be reclaimed after ExitBootService(),
    linux kernel reserves MOK config table when it detects the existence of
    the table, so it's fine to allocate the table as BootServicesData.

    Signed-off-by: Gary Lin <glin@suse.com>
```

```
commit 493bd940e5c6e28e673034687de7adef9529efff
Author: Peter Jones <pjones@redhat.com>
Date:   Sat Apr 10 16:05:23 2021 -0400

    Don't call QueryVariableInfo() on EFI 1.10 machines

    The EFI 1.10 spec (and presumably earlier revisions as well) didn't have
    RT->QueryVariableInfo(), and on Chris Murphy's MacBookPro8,2 , that
    memory appears to be initialized randomly.

    This patch changes it to not call RT->QueryVariableInfo() if the
    EFI_RUNTIME_SERVICES table's major revision is less than two, and
    assumes our maximum variable size is 1024 in that case.

    Signed-off-by: Peter Jones <pjones@redhat.com>
```

```
commit 05875f3aed1c90fe071c66de05744ca2bcbc2b9e
Author: Peter Jones <pjones@redhat.com>
Date:   Thu May 13 20:42:18 2021 -0400

    Post-process our PE to be sure.

    On some versions of binutils[0], including binutils-2.23.52.0.1-55.el7,
    do not correctly initialize the data when computing the PE optional
    header checksum.  Unfortunately, this means that any time you get a
    build that reproduces correctly using the version of objcopy from those
    versions, it's just a matter of luck.

    This patch introduces a new utility program, post-process-pe, which does
    some basic validation of the resulting binaries, and if necessary,
    performs some minor repairs:

    - sets the timestamp to 0
      - this was previously done with dd using constant offsets that aren't
        really safe.
    - re-computes the checksum.

    [0] I suspect, but have not yet fully verified, that this is
        accidentally fixed by the following upstream binutils commit:

        commit cf7a3c01d82abdf110ef85ab770e5997d8ac28ac
        Author: Alan Modra <amodra@gmail.com>
        Date:   Tue Dec 15 22:09:30 2020 +1030`

          Lose some COFF/PE static vars, and peicode.h constify

          This patch tidies some COFF and PE code that unnecessarily used static
          variables to communicate between functions.

    v2 - MAP_PRIVATE was totally wrong...

    Signed-off-by: Peter Jones <pjones@redhat.com>
```

```
commit 9f973e4e95b1136b8c98051dbbdb1773072cc998
Author: Gary Lin <glin@suse.com>
Date:   Tue May 11 10:41:43 2021 +0800

    Relax the check for import_mok_state()

    An openSUSE user reported(*) that shim 15.4 failed to boot the system
    with the following message:

      "Could not create MokListXRT: Out of Resources"

    In the beginning, I thought it's caused by the growing size of
    vendor-dbx. However, we found the following messages after set
    SHIM_VERBOSE:

      max_var_sz:8000 remaining_sz:85EC max_storage_sz:9000
      SetVariable(“MokListXRT”, ... varsz=0x1404) = Out of Resources

    Even though the firmware claimed the remaining storage size is 0x85EC
    and the maximum variable size is 0x8000, it still rejected MokListXRT
    with size 0x1404. It seems that the return values from QueryVariableInfo()
    are not reliable. Since this firmware didn't really support Secure Boot,
    the variable mirroring is not so critical, so we can just accept the
    failure of import_mok_state() and continue boot.

    (*) https://bugzilla.suse.com/show_bug.cgi?id=1185261

    Signed-off-by: Gary Lin <glin@suse.com>
```

```
commit 4d64389c6c941d21548b06423b8131c872e3c3c7
Author: Chris Coulson <chris.coulson@canonical.com>
Date:   Mon Jun 7 16:34:18 2021 +0100

    shim: another attempt to fix load options handling

    The load options handling is quite complicated and tries to accomodate
    several scenarios, but there are currently multiple issues:

    - If the supplied LoadOptions is an EFI_LOAD_OPTION structure,
    second_stage gets initialized to the entire contents of the OptionalData
    field and load_options is initialized to NULL, which means it isn't
    possible to pass additional options to the second stage loader (and it
    looks like the intention is for this to be supported).

    - If the supplied LoadOptions contains 2 or more strings, the code seems
    to assume that shim was executed from the UEFI shell and that the first
    argument is the path of the shim executable, so it's ignored. But this
    breaks the ability to pass additional options to the second stage loader
    from BDS on firmware implementations that initialize LoadOptions to just
    the OptionalData field of the EFI_LOAD_OPTION, which is what EDK2 seems
    to do.

    This is moot anyway because this case (strings == 2) doesn't actually seem
    to work, as nothing sets loader_len and therefore second_stage is not set
    to the custom loader path.

    - If the supplied LoadOptions contains a single string that isn't shim's
    path, nothing sets loader_len and therefore second_stage isn't set at the
    end of set_second_stage.

    - set_second_stage replaces L' ' characters with L'\0' - whilst this is
    useful to NULL terminate the path for the second stage, it doesn't seem
    quite right to do this for the remaining LoadOptions data. Grub's
    chainloader command supplies additional arguments as a NULL-terminated
    space-delimited string via LoadOptions. Making it NULL-delimited seems to
    be incompatible with the kernel's commandline handling, which wouldn't
    work for scenarios where you might want to direct-boot a kernel image
    (wrapped in systemd's EFI stub) from shim.

    - handle_image passes the original LoadOptions to the second stage if
    load_options is NULL, which means that the second stage currently always
    gets shim's load options.

    I've made an attempt to try to fix things. After the initial
    checks in set_second_stage, it now does this:

    - Tries to parse LoadOptions as an EFI_LOAD_OPTION in order to extract
    the OptionalData if it is.
    - If it's not an EFI_LOAD_OPTION, check if the first string is the
    current shim path and ignore it if it is (the UEFI shell case).
    - Split LoadOptions in to a single NULL terminated string (used to
    initialize second_stage) and the unmodified remaining data (used to
    initialize load_options and load_options_size).
    I've also modified handle_image to always set LoadOptions and
    LoadOptionsSize. If shim is executed with no options, or is only
    executed with a single option to override the second stage loader
    path, the second stage is executed with LoadOptions = NULL and
    LoadOptionsSize = 0 now.

    I've tested this on EDK2 and I can load a custom loader with extra
    options from both BDS and the UEFI shell:

    FS0:\> shimx64.efi test.efi
    LoadOptionsSize: 0
    LoadOptions: (null)
    FS0:\> shimx64.efi       test.efi
    LoadOptionsSize: 0
    LoadOptions: (null)
    FS0:\> shimx64.efi test.efi foo bar
    LoadOptionsSize: 16
    LoadOptions: foo bar
```

```
commit 7501b6bb449f6e4d13e700a65650f9308f54c8c1
Author: Jonathan Yong <jonathan.yong@intel.com>
Date:   Fri Apr 16 09:59:03 2021 +0800

    mok: fix potential buffer overrun in import_mok_state

    Fix the case where data_size is 0, so config_template is
    not implicitly copied like the size calculation above.

    upstream-status: https://github.com/rhboot/shim/issues/249

    Signed-off-by: Jonathan Yong <jonathan.yong@intel.com>
```

```
commit 4583db41ea58195956d4cdf97c43a195939f906b
Author: Seth Forshee <seth.forshee@canonical.com>
Date:   Sat Jun 5 07:34:44 2021 -0500

    Don't unhook ExitBootServices() when EBS protection is disabled

    When EBS protection is disabled the code which hooks into EBS is
    complied out, but on unhook it's the code which restores Exit() that
    is disabled. This appears to be a mistake, and it can result in
    writing NULL to EBS in the boot services table.

    Fix this by moving the ifdefs to compile out the code to unhook EBS
    instead of the code to unhook Exit(). Also ifdef the definition of
    system_exit_boot_services to safeguard against its accidental use.

    Fixes: 4b0a61dc9a95 ("shim: compile time option to bypass the ExitBootServices() check")
    Signed-off-by: Seth Forshee <seth.forshee@canonical.com>
```

-------------------------------------------------------------------------------
If bootloader, shim loading is, GRUB2: is CVE-2020-14372, CVE-2020-25632,
 CVE-2020-25647, CVE-2020-27749, CVE-2020-27779, CVE-2021-20225, CVE-2021-20233,
 CVE-2020-10713, CVE-2020-14308, CVE-2020-14309, CVE-2020-14310, CVE-2020-14311,
 CVE-2020-15705, and if you are shipping the shim_lock module CVE-2021-3418
-------------------------------------------------------------------------------

> We have no plans to use GRUB2 as a second stage loader.  Our intention is to
bundle the Linux Kernel, initramfs, and kernel command line into a single EFI
binary such that the PE/COFF signature protects all of those components.  We
are using a small EFI stub, based on the systemd-boot stub, to do this and we
have augmented it to add support for a SBAT section.
>
> The "stubby" EFI shim: https://github.com/puzzleos/stubby

-------------------------------------------------------------------------------
What exact implementation of Secureboot in GRUB2 ( if this is your bootloader ) you have ?
* Upstream GRUB2 shim_lock verifier or * Downstream RHEL/Fedora/Debian/Canonical like implementation ?
-------------------------------------------------------------------------------

> See our answer to the question regarding GRUB2; we plan to boot the Linux
Kernel directly using the shim.

-------------------------------------------------------------------------------
If bootloader, shim loading is, GRUB2, and previous shims were trusting affected
by CVE-2020-14372, CVE-2020-25632, CVE-2020-25647, CVE-2020-27749,
  CVE-2020-27779, CVE-2021-20225, CVE-2021-20233, CVE-2020-10713,
  CVE-2020-14308, CVE-2020-14309, CVE-2020-14310, CVE-2020-14311, CVE-2020-15705,
  and if you were shipping the shim_lock module CVE-2021-3418
  ( July 2020 grub2 CVE list + March 2021 grub2 CVE list )
  grub2:
* were old shims hashes provided to Microsoft for verification
  and to be added to future DBX update ?
* Does your new chain of trust disallow booting old, affected by CVE-2020-14372,
  CVE-2020-25632, CVE-2020-25647, CVE-2020-27749,
  CVE-2020-27779, CVE-2021-20225, CVE-2021-20233, CVE-2020-10713,
  CVE-2020-14308, CVE-2020-14309, CVE-2020-14310, CVE-2020-14311, CVE-2020-15705,
  and if you were shipping the shim_lock module CVE-2021-3418
  ( July 2020 grub2 CVE list + March 2021 grub2 CVE list )
  grub2 builds ?
-------------------------------------------------------------------------------

> This is our first shim review submission for PuzzleOS, complete with new
vendor certificates that have not previously signed any second stage loaders or
EFI binaries.  Further, the shim in this submission implements SBAT boot
enforcement to control which SBAT qualified binaries are allowed to boot.
Booting legacy and vulnerable EFI binaries should not be a concern.

-------------------------------------------------------------------------------
If your boot chain of trust includes linux kernel, is
"efi: Restrict efivar_ssdt_load when the kernel is locked down"
upstream commit 1957a85b0032a81e6482ca4aab883643b8dae06e applied ?
Is "ACPI: configfs: Disallow loading ACPI tables when locked down"
upstream commit 75b0cea7bf307f362057cc778efe89af4c615354 applied ?
-------------------------------------------------------------------------------

> We do not currently plan to sign Linux Kernels prior to v5.10 which contains
both of the commits mentioned above.

-------------------------------------------------------------------------------
If you use vendor_db functionality of providing multiple certificates and/or
hashes please briefly describe your certificate setup. If there are allow-listed hashes
please provide exact binaries for which hashes are created via file sharing service,
available in public with anonymous access for verification
-------------------------------------------------------------------------------

> The shim presented here consists of three vendor certificates: a "production"
certificate, a "management" certificate, and a "limited" certificate.  The PEM
formatted certificates are available in the "config/certs/" directory.  No
hashes are present in the shim's allow-list.
>
> The different vendor certificates, and the associated signed boot chain, are
used in conjunction with the TPM's PCR7 and TPM Extended Authorization policies
to control access to TPM based secrets such that only authorized OS kernels are
allowed to access secrets stored in the TPM's NVRAM.

-------------------------------------------------------------------------------
If you are re-using a previously used (CA) certificate, you will need
to add the hashes of the previous GRUB2 binaries to vendor_dbx in shim
in order to prevent GRUB2 from being able to chainload those older GRUB2
binaries. If you are changing to a new (CA) certificate, this does not
apply. Please describe your strategy.
-------------------------------------------------------------------------------

> This is our first shim review submission for PuzzleOS, complete with new
vendor certificates that have not previously signed any second stage loaders or
EFI binaries.

-------------------------------------------------------------------------------
What OS and toolchain must we use to reproduce this build?  Include where to find it, etc.  We're going to try to reproduce your build as close as possible to verify that it's really a build of the source tree you tell us it is, so these need to be fairly thorough. At the very least include the specific versions of gcc, binutils, and gnu-efi which were used, and where to find those binaries.
If the shim binaries can't be reproduced using the provided Dockerfile, please explain why that's the case and what the differences would be.
-------------------------------------------------------------------------------

> The included Makefile and Dockerfile are the same as what we used to build
our shim artifacts for review.  A new shim can be built using the `make build`
command.

-------------------------------------------------------------------------------
Which files in this repo are the logs for your build?   This should include logs for creating the buildroots, applying patches, doing the build, creating the archives, etc.
-------------------------------------------------------------------------------

> The build log and relevant shim build artifacts can be found in the
"artifacts.YYYYMMDDHHMMSS" directory.
```
% cd artifacts.*
% ls -1
build.log
fbx64.efi
mmx64.efi
shim-git_commit_extra.log
shimx64.efi
vendor_db.esl
% sha256sum *
a3e11112ae3e4dae7a3371734482755765cf76c12730c787136e241aae6b3a6e  build.log
961e1bcf7f7b0da3fbe962039ba0d6be7eb3057c81c63dd613b7e385729ab08b  fbx64.efi
e1bd0ce63b172c4e948eef9968d78ff3600a4db265e60b1c308ae43b591c6ba3  mmx64.efi
a1e8e98c7121c9a6f860e21e202cf6cc269aaf77bfb3d31ebb60322e7412b210  shim-git_commit_extra.log
dcd87466f988a0c6e88912e34c2c045a1ddb4547318dbe59f8d3749c8c2019fb  shimx64.efi
0950f70d1dce96ac227a09f4885356df2527de75891b6ca5c703a0af800bbccb  vendor_db.esl
```

-------------------------------------------------------------------------------
Add any additional information you think we may need to validate this shim
-------------------------------------------------------------------------------

> Included an ASCII art rendering of two puzzle pieces that original submitter,
Paul Moore thought looked pretty cool. And so do I.

```

                         ____
                        /\  __\_
                       /  \/ \___\
                       \     /___/
                    /\_/     \    \
                   /          \____\
               ___/\       _  /    /
              / \/  \     /_\/____/
              \     /     \___\
              /     \_/\  /   /
             /          \/___/
             \  _       /   /
              \/_|     /___/
                 /     \___\
                 \  /\_/___/
                  \/___/

```

> Credit to '[n4biS]' and https://ascii.co.uk/art/puzzle
