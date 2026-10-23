/***************************************************************************
 *   Copyright (C) 2009-2012 by Clockwise   *
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

#import "FileUtil.h"

static NSString *dataDirectory = nil;

@implementation FileUtil

+ (NSString*)dataDirectory
{
	if (dataDirectory == nil) {
		NSArray *array = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
		dataDirectory = [[array objectAtIndex:0] stringByAppendingString:@"/Gas Mask/"];
	}
	return dataDirectory;
}

+ (NSString*)localHostFilesDirectory
{
	return [[FileUtil dataDirectory] stringByAppendingString:@"Local/"];
}

+ (NSString*)remoteHostFilesDirectory
{
	return [[FileUtil dataDirectory] stringByAppendingString:@"Remote/"];
}

+ (NSString*) combinedHostsFilesDirectory
{
    return [[FileUtil dataDirectory] stringByAppendingString:@"Combined/"];
}

+ (BOOL)moveToTrash:(NSString *)path
{
	NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:path]) {
		logDebug(@"File not found: \"%@\"", path);
		return NO;
	}
	
	NSError *error = nil;
	if (![manager trashItemAtURL:[NSURL fileURLWithPath:path] resultingItemURL:nil error:&error]) {
		logDebug(@"Failed to move \"%@\" to Trash: %@", path, error);
		return NO;
	}
	return YES;
}

@end
