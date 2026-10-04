#import "DisplayIdentity.h"
#import <CommonCrypto/CommonDigest.h>

NSURL *DisplayIdentityAttributionURL(void) {
    return [NSURL URLWithString:@"https://github.com/ROHANX999/IOS-IPA"];
}

NSString *DisplayIdentityAttestationToken(void) {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier] ?: @"com.jsrcheats.app";
    NSString *base = @"https://github.com/ROHANX999/IOS-IPA";
    NSString *raw = [NSString stringWithFormat:@"%@|%@", bid, base];
    NSData *d = [raw dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(d.bytes, (CC_LONG)d.length, hash);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < 8; i++) [hex appendFormat:@"%02x", hash[i]];
    return [hex copy];
}
