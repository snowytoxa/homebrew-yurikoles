class FuseExt2 < Formula
  desc "FUSE module to mount ext{2,3,4} file systems with read/write support"
  homepage "https://github.com/alperakcan/fuse-ext2"
  head "https://github.com/alperakcan/fuse-ext2.git"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "e2fsprogs"
  depends_on :osxfuse

  conflicts_with "ext2fuse"

  def install
    ENV.append "LIBS", "-losxfuse"
    ENV.append "CFLAGS", "-idirafter/usr/local/include/osxfuse/fuse"
    ENV.append "CFLAGS", "--std=gnu89" if ENV.compiler == :clang

    # Include e2fsprogs headers *after* system headers with -idirafter
    # as uuid/uuid.h system header is shadowed by e2fsprogs headers
    ENV.remove "HOMEBREW_INCLUDE_PATHS", Formula["e2fsprogs"].include
    ENV.append "CFLAGS", "-idirafter" + Formula["e2fsprogs"].include

    system "./autogen.sh"
    system "./configure", "--disable-debug", "--disable-dependency-tracking", "--prefix=#{prefix}"

    system "make"

    # 1 - make prefpane (not done by default)
    # 2 - Force tools/macosx section to install under prefix path instead
    #     as installing to default /System requires the root user
    system "cd tools/macosx && DESTDIR=#{prefix}/System make prefpane install"

    system "cd fuse-ext2 && make install"
  end

  def caveats
    <<~EOS
      For #{name} to be able to work properly, the filesystem extension and
      preference pane must be installed by the root user:

        sudo cp -pR #{prefix}/System/Library/Filesystems/fuse-ext2.fs /Library/Filesystems/
        sudo chown -R root:wheel /Library/Filesystems/fuse-ext2.fs

        sudo cp -pR #{prefix}/System/Library/PreferencePanes/fuse-ext2.prefPane /Library/PreferencePanes/
        sudo chown -R root:wheel /Library/PreferencePanes/fuse-ext2.prefPane

      Removing properly the filesystem extension and the preference pane
      must be done by the root user:

        sudo rm -rf /Library/Filesystems/fuse-ext2.fs
        sudo rm -rf /Library/PreferencePanes/fuse-ext2.prefPane
    EOS
  end

  test do
    # Can't test more here as an ext2 image mounting test
    # would require fuse-ext2.fs to be installed (see caveats)
    assert_match "FUSE EXT2FS Driver", `#{bin}/fuse-ext2`
  end
end
