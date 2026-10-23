/***************************************************************************
 *   Copyright (C) 2009-2013 by Clockwise   *
 *   copyright@clockwise.ee   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

#import "PrivilegedActions.h"

// AuthorizationExecuteWithPrivileges has been deprecated since OS X 10.7 and
// may be removed in a future macOS release. Privileged commands are now run via
// AppleScript's "do shell script ... with administrator privileges", which shows
// the standard system authentication dialog and caches the credentials for a
// few minutes, so a single prompt covers a sequence of commands.

static BOOL authorized;

@interface PrivilegedActions (Private)
+ (BOOL)execute:(NSString *)command withArguments:(NSArray<NSString *> *)arguments prompt:(NSString *)prompt;
+ (BOOL)runAppleScript:(NSString *)source;
+ (NSString *)shellQuoted:(NSString *)string;
+ (NSString *)appleScriptQuoted:(NSString *)string;
@end

@implementation PrivilegedActions

+(BOOL)removeFile:(NSString*)path
{
	if (![self authorized] && ![self authorize]) {
		return NO;
	}
	
	return [self execute:@"/bin/rm" withArguments:@[@"-fr", path] prompt:nil];
}

+ (BOOL)copyFile:(NSString*)source to:(NSString*)destination
{
	if (![self authorized] && ![self authorize]) {
		return NO;
	}
	
	return [self execute:@"/bin/cp" withArguments:@[source, destination] prompt:nil];
}

+ (BOOL)makeWritableForCurrentUser:(NSString*)path prompt:(NSString*)prompt
{
	if (![self authorized] && ![self authorizeWithPrompt:prompt]) {
		return NO;
	}
	
	logDebug(@"Making %@ writable for user %@", path, NSUserName());
	
	NSString *arg = [NSString stringWithFormat:@"user:%@:allow write", NSUserName()];
	return [self execute:@"/bin/chmod" withArguments:@[@"+a", arg, path] prompt:prompt];
}

+(BOOL)authorized
{
	return authorized;
}

+(BOOL)authorize
{
	return [self authorizeWithPrompt:nil];
}

+ (BOOL)authorizeWithPrompt:(NSString*)prompt
{
	authorized = [self execute:@"/usr/bin/true" withArguments:@[] prompt:prompt];
	if (!authorized) {
		logDebug(@"Failed to Authorize");
	}
	return authorized;
}

@end

@implementation PrivilegedActions(Private)

+ (BOOL)execute:(NSString *)command withArguments:(NSArray<NSString *> *)arguments prompt:(NSString *)prompt
{
	NSMutableArray *parts = [NSMutableArray arrayWithObject:[self shellQuoted:command]];
	for (NSString *argument in arguments) {
		[parts addObject:[self shellQuoted:argument]];
	}
	
	NSMutableString *source = [NSMutableString stringWithFormat:@"do shell script %@ with administrator privileges",
							   [self appleScriptQuoted:[parts componentsJoinedByString:@" "]]];
	if ([prompt length] > 0) {
		[source appendFormat:@" with prompt %@", [self appleScriptQuoted:prompt]];
	}
	
	BOOL success = [self runAppleScript:source];
	if (!success) {
		// Credentials may have expired or been revoked; ask again next time.
		authorized = NO;
	}
	return success;
}

+ (BOOL)runAppleScript:(NSString *)source
{
	// NSAppleScript is not thread safe and must be used on the main thread.
	if (![NSThread isMainThread]) {
		__block BOOL result = NO;
		dispatch_sync(dispatch_get_main_queue(), ^{
			result = [self runAppleScript:source];
		});
		return result;
	}
	
	NSDictionary *error = nil;
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:source];
	NSAppleEventDescriptor *result = [script executeAndReturnError:&error];
	if (result == nil) {
		logError(@"Privileged command failed: %@", error);
		return NO;
	}
	return YES;
}

+ (NSString *)shellQuoted:(NSString *)string
{
	NSString *escaped = [string stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
	return [NSString stringWithFormat:@"'%@'", escaped];
}

+ (NSString *)appleScriptQuoted:(NSString *)string
{
	NSString *escaped = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
	escaped = [escaped stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
	return [NSString stringWithFormat:@"\"%@\"", escaped];
}

@end
