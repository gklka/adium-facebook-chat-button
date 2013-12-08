/*
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "GKFacebookChatLinkToolbarItemPlugin.h"

#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>

#import <Adium/AIToolbarControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIChat.h>

#import <AdiumLibpurple/AIFacebookXMPPAccount.h>
#import <AdiumLibpurple/ESPurpleJabberAccount.h>

// #import "AIFacebookXMPPAccount.h"

#define FACEBOOK_LINK_IDENTIFER	@"FacebookChatLink"

@interface GKFacebookChatLinkToolbarItemPlugin ()
- (IBAction)openInSafari:(id)sender;
- (AIChat *)chatForToolbar:(NSToolbarItem *)senderItem;
- (BOOL)verifyContact:(AIListContact *)listContact;
- (BOOL)contactIsFacebookChat:(AIListObject *)object;
- (BOOL)validateToolbarItem:(NSToolbarItem *)senderItem;
@end

/*!
 * @class GKFacebookChatLinkToolbarItemPlugin
 * @brief Component to add a toolbar item which opens Facebook chats in Safari
 */
@implementation GKFacebookChatLinkToolbarItemPlugin

#pragma mark - Plugin details
/*!
 @brief Returns Plugin Author
 */
- (NSString *)pluginAuthor {
	return @"Gruber Kristóf";
}
/*!
 @brief Returns webpages about plugin
 */
- (NSString *)pluginURL {
	return @"http://gk.lka.hu";
}

/*!
 @brief Returns plugin version
 */
- (NSString *)pluginVersion {
	return @"1.0.1";
}

/*!
 @brief Returns plugin description
 */
- (NSString *)pluginDescription {
	return @"Adium plugin for adding a toolbar button which opens Facebook chats in Safari";
}

#pragma mark - Actual code
/*!
 * @brief Install
 */
- (void)installPlugin
{
	NSToolbarItem *toolbarItem;
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:FACEBOOK_LINK_IDENTIFER
														  label:[NSString stringWithFormat:AILocalizedString(@"Open Chat",nil)]
												   paletteLabel:[NSString stringWithFormat:AILocalizedString(@"Open Chat in Safari",nil)]
														toolTip:[NSString stringWithFormat:AILocalizedString(@"View the current chat on Facebook in Safari",nil)]
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:@"facebook" forClass:[self class] loadLazily:YES]
														 action:@selector(openInSafari:)
														   menu:nil];
	[[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
}

/*!
 * @brief Get the Facebook user ID from chat contact's listObject, and open Facebook's chat URL in the default Browser
 */
- (IBAction)openInSafari:(id)sender
{
    if (![sender isKindOfClass:[NSToolbarItem class]]) {
        return;
    }
    
    // get the chat
    NSToolbarItem *toolbarItem = (NSToolbarItem *)sender;
    AIChat *chat = [self chatForToolbar:toolbarItem];
    
    // get the contact username
    NSString *facebookUsername;
    facebookUsername = chat.listObject.UID;
    
    // get the facebook userid
    NSArray *parts = [facebookUsername componentsSeparatedByString:@"@"];
    NSString *facebookUID = [parts objectAtIndex:0];
    facebookUID = [facebookUID stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    // open it in the default browser
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://facebook.com/messages/%@/", facebookUID]]]; // facebook will redirect if user is using https
}

#pragma mark - Helper functions

- (BOOL)validateToolbarItem:(NSToolbarItem *)senderItem
{
	// Get the chat for this window.
	AIChat *chat = [self chatForToolbar:senderItem];
	
	// Don't handle group chats.
	if (!chat || chat.isGroupChat) {
		return NO;
	}
	
	// Return if the contact can be notified.
	return [self contactIsFacebookChat:chat.listObject];
}

- (BOOL)contactIsFacebookChat:(AIListObject *)object
{
	// Don't handle groups.
	if (![object isKindOfClass:[AIListContact class]]) {
		return NO;
	}
	
//    NSLog(@"GKFacebookChatLinkToolbarItemPlugin: %@", [object class]);
    
	if ([object isKindOfClass:[AIMetaContact class]]) {
		for (AIListContact *contact in [(AIMetaContact *)object uniqueContainedObjects]) {
            return [self verifyContact:contact];
		}
        return NO;
	} else {
        return [self verifyContact:((AIListContact *)object)];
	}
}

- (BOOL)verifyContact:(AIListContact *)listContact
{
    // user is either using Facebook directly
    if ([listContact.account isKindOfClass:[AIFacebookXMPPAccount class]]) {
        return YES;
    }
    
    // or is Czo, who configured it through XMPP
    if ([listContact.account isKindOfClass:[ESPurpleJabberAccount class]]) {
        return [listContact.UID rangeOfString:@"chat.facebook.com"].location != NSNotFound;
    }
    
    return NO;
}

- (AIChat *)chatForToolbar:(NSToolbarItem *)senderItem
{
	NSToolbar		*windowToolbar = nil;
	NSToolbar		*senderToolbar = [senderItem toolbar];
    
	//for each open window
	for (NSWindow *currentWindow in [NSApp windows]) {
		//if it has a toolbar & it's ours
		if ((windowToolbar = [currentWindow toolbar]) && (windowToolbar == senderToolbar)) {
			return [adium.interfaceController activeChatInWindow:currentWindow];
		}
	}
	
	return nil;
}

@end
