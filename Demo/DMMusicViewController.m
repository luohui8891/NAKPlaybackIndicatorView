//
//  DMMusicViewController.m
//  NAPlaybackIndicatorView
//
//  Created by Yuji Nakayama on 1/30/14.
//  Copyright (c) 2014 Yuji Nakayama. All rights reserved.
//

#import "DMMusicViewController.h"
#import <NAPlaybackIndicatorView/NAPlaybackIndicatorView.h>
#import "DMMusicPlayerController.h"
#import "DMMediaItem.h"
#import "DMSongCell.h"

@interface DMMusicViewController ()

@property (nonatomic, readonly) MPMusicPlayerController* musicPlayer;
@property (nonatomic, readonly) NSArray* collections;

@end

@implementation DMMusicViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self prepareMediaPlayer];

    self.navigationItem.title = @"Music";
    self.tableView.separatorInset = UIEdgeInsetsMake(0.0, 15.0, 0.0, 15.0);
}

- (void)prepareMediaPlayer
{
#if TARGET_IPHONE_SIMULATOR
    NSMutableArray* songs = [NSMutableArray array];

    for (NSInteger i = 1; i <= 20; i++) {
        [songs addObject:[DMMediaItem randomSongWithAlbumTrackNumber:i]];
    }

    MPMediaItemCollection* collection = [MPMediaItemCollection collectionWithItems:songs];
    _collections = @[collection];

    _musicPlayer = (MPMusicPlayerController*)[DMMusicPlayerController iPodMusicPlayer];
#else
    MPMediaQuery* query = [MPMediaQuery albumsQuery];
    _collections = query.collections;

    _musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
#endif

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(musicPlayerDidChangeNowPlayingItem:)
                                                 name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                                               object:self.musicPlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(musicPlayerDidChangePlaybackState:)
                                                 name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
                                               object:self.musicPlayer];
    [self.musicPlayer beginGeneratingPlaybackNotifications];
}

- (void)dealloc
{
    [self.musicPlayer endGeneratingPlaybackNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableview data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.collections.count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    MPMediaItemCollection* collection = self.collections[section];
    return [collection.representativeItem valueForProperty:MPMediaItemPropertyAlbumTitle];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MPMediaItemCollection* collection = self.collections[section];
    return collection.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kCellIdentifier = @"Cell";

    DMSongCell* cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];

    if (!cell) {
        cell = [[DMSongCell alloc] initWithReuseIdentifier:kCellIdentifier];
    }

    cell.song = [self songAtIndexPath:indexPath];
    [self updatePlaybackIndicatorOfCell:cell];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MPMediaItem* song = [self songAtIndexPath:indexPath];

    if (self.musicPlayer.playbackState == MPMusicPlaybackStateStopped) {
        [self playSongAtIndexPath:indexPath];
    } else if (self.musicPlayer.playbackState == MPMusicPlaybackStatePaused) {
        if ([self isNowPlayingSong:song]) {
            [self.musicPlayer play];
        } else {
            [self playSongAtIndexPath:indexPath];
        }
    } else {
        if ([self isNowPlayingSong:song]) {
            [self.musicPlayer pause];
        } else {
            [self playSongAtIndexPath:indexPath];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Helpers

- (MPMediaItem*)songAtIndexPath:(NSIndexPath*)indexPath
{
    MPMediaItemCollection* collection = self.collections[indexPath.section];
    return collection.items[indexPath.row];
}

- (void)playSongAtIndexPath:(NSIndexPath*)indexPath
{
    MPMediaItemCollection* album = self.collections[indexPath.section];

    [self.musicPlayer setQueueWithItemCollection:album];
    self.musicPlayer.nowPlayingItem = album.items[indexPath.row];
    [self.musicPlayer play];
}

- (BOOL)isNowPlayingSong:(MPMediaItem*)song
{
    uint64_t targetID = [[song valueForProperty:MPMediaItemPropertyPersistentID] unsignedLongLongValue];
    uint64_t nowPlayingID = [[self.musicPlayer.nowPlayingItem valueForProperty:MPMediaItemPropertyPersistentID] unsignedLongLongValue];
    return targetID == nowPlayingID;
}

- (void)updatePlaybackIndicatorOfVisibleCells
{
    for (DMSongCell* cell in self.tableView.visibleCells) {
        [self updatePlaybackIndicatorOfCell:cell];
    }
}

- (void)updatePlaybackIndicatorOfCell:(DMSongCell*)cell
{
    if ([self isNowPlayingSong:cell.song]) {
        if (self.musicPlayer.playbackState == MPMusicPlaybackStatePaused) {
            cell.state = NAPlaybackIndicatorViewStatePaused;
        } else {
            cell.state = NAPlaybackIndicatorViewStatePlaying;
        }
    } else {
        cell.state = NAPlaybackIndicatorViewStateStopped;
    }
}

#pragma mark - Notifications

- (void)musicPlayerDidChangeNowPlayingItem:(NSNotification*)notification
{
    [self updatePlaybackIndicatorOfVisibleCells];
}

- (void)musicPlayerDidChangePlaybackState:(NSNotification*)notification
{
    [self updatePlaybackIndicatorOfVisibleCells];
}

@end
