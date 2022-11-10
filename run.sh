#!/bin/bash
#shellcheck disable=SC2034
#shellcheck disable=SC2154
#shellcheck disable=SC1090

display_usage() {
    echo "# Error!"
    echo "This script must have arguments specifying app version, app identifier and conf file."
    echo -e "Usage: $0 [1.x.x][reverse.dns.thing][/path/to/conf] \n"
}
if [[ "$projectfolder" = "" ]]; then
    display_usage
    exit 1
fi


# Pull conf file for notarization
source "$3"

/usr/libexec/Plistbuddy -c "Set CFBundleVersion $version" "$plist"
/usr/libexec/Plistbuddy -c "Set CFBundleShortVersionString $bundle_short_version" "$plist"

xattr -rc "$product"

codesign --force --options runtime --deep --sign "$devAppID" "$product"

zip -r "$product".zip "$product"

xcrun notarytool submit "$product".zip --keychain-profile "$keychain_profile" --wait

exit 0

xcrun stapler staple "$product"

rm "$product".zip

pkgbuild --root output --identifier "$identifier" --version "$version" --install-location "/Applications" --sign "$devInstID" "$pkgname"_unsigned.pkg

productbuild --synthesize --package "$pkgname"_unsigned.pkg distribution.dist

productbuild --distribution distribution.dist --sign "$devInstID" --package-path "$pkgname"_unsigned.pkg --resources . --version "$version" "$pkgname".pkg

xcrun notarytool submit "$pkgname" "$version".pkg --apple-id "$appleID" --keychain-profile "$keychain_profile" --team-id "$teamID" --wait

xcrun stapler staple "$pkgname"_"$version".pkg
