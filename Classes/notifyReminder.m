/***************
 notifyReminder.m
 Copyright 2013-2016 Robert T. Miller
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 *****************/

//
//  notifyReminder.m
//  rTracker
//
//  Created by Rob Miller on 07/11/2013.
//  Copyright (c) 2013 Robert T. Miller. All rights reserved.
//

#import "notifyReminder.h"

#import "tObjBase.h"
#import "trackerObj.h"

#import "dbg-defs.h"
#import "rTracker-resource.h"

@implementation notifyReminder

@synthesize rid=_rid, monthDays=_monthDays, weekDays=_weekDays, everyMode=_everyMode, everyVal=_everyVal, start=_start, until=_until, times=_times, timesRandom=_timesRandom, msg=_msg, soundFileName=_soundFileName, reminderEnabled=_reminderEnabled, untilEnabled=_untilEnabled, fromLast=_fromLast, saveDate=_saveDate, notifContent=_notifContent, tid=_tid, vid=_vid;

#define UNTILFLAG   (0x01<<0)
#define TIMESRFLAG  (0x01<<1)
#define ENABLEFLAG  (0x01<<2)
#define FROMLASTFLAG  (0x01<<3)

- (id)init {
	
	if ((self = [super init])) {
        self.notifContent = nil;
        self.saveDate = (int) [[NSDate date] timeIntervalSince1970];
        self.soundFileName = nil;
	}
	
	return self;
}
/*
- (id)init:(trackerObj*) tObjIn {
	if ((self = [self init])) {
		//DBGLog(@"init trackerObj id: %d",tid);
		self.to = tObjIn;
        [self initReminderTable];
        [self nextRid];
	}
	return self;
}
*/

- (id)init:(NSNumber*)inRid to:(trackerObj*)to {
	if ((self = [self init])) {
		//DBGLog(@"init trackerObj id: %d",tid);
        //[self initReminderTable];
        [self loadRid:[NSString stringWithFormat:@"rid=%d and tid=%ld",[inRid intValue], (long)to.toid] to:to];
	}
    DBGLog(@"%@",self);
	return self;
    
}

- (id) initWithDict:(NSDictionary*)dict {

    if((self = [super init])) {
        self.rid = [dict[@"rid"] intValue];
        self.monthDays = (uint32_t) [dict[@"monthDays"] unsignedIntValue];
        self.weekDays = (uint8_t) [dict[@"weekDays"] unsignedIntValue];
        self.everyMode = (uint8_t) [dict[@"everyMode"] unsignedIntValue];
        self.everyVal = [dict[@"everyVal"] intValue];
        self.start = [dict[@"start"] intValue];
        self.until = [dict[@"until"] intValue];
        self.times = [dict[@"times"] intValue];
        self.msg = (NSString*) dict[@"msg"];
        self.soundFileName = (NSString*) dict[@"soundFile"];
        
        [self putFlags:[dict[@"flags"] unsignedIntValue]];
        
        self.tid = [dict[@"tid"] intValue];
        self.vid = [dict[@"vid"] intValue];
        
        self.saveDate = [dict[@"saveDate"] intValue];
    }
    DBGLog(@"%@",self);
    return self;
}

- (void)dealloc {
	//DBGLog(@"nr dealloc");
}

- (void) save:(trackerObj*)to {
    unsigned int flags= [self getFlags];

    DBGLog(@"%@",self);
    NSString *sql = [NSString stringWithFormat:
                   @"insert or replace into reminders (rid, monthDays, weekDays, everyMode, everyVal, start, until, times, flags, tid, vid, saveDate, msg, soundFileName) values (%ld, %d, %d, %d,%ld, %ld, %ld, %ld, %d, %ld, %ld, %ld, '%@', '%@')",
                   (long)self.rid,self.monthDays,self.weekDays,self.everyMode,(long)self.everyVal,(long)self.start, (long)self.until, (long)self.times, flags, (long)self.tid,(long)self.vid, (long)self.saveDate, self.msg, self.soundFileName];
    DBGLog(@"save sql= %@",sql);
    [to toExecSql:sql];
  //sql = nil;
}
/*
 // not used - db updates only on tracker saveConfig
- (void) delete:(trackerObj*)to {
    if (!self.rid) return;
   sql = [NSString stringWithFormat:@"delete from reminders where rid=%d",self.rid];
    [to toExecSql:sql];
  //sql = nil;
}
*/
- (unsigned int) getFlags {
    unsigned int flags=0;
    if (self.timesRandom) flags |= TIMESRFLAG;
    if (self.reminderEnabled) flags |= ENABLEFLAG;
    if (self.untilEnabled) flags |= UNTILFLAG;
    if (self.fromLast) flags |= FROMLASTFLAG;
    return flags;
}

- (void) putFlags:(unsigned int)flags {
    self.timesRandom = (flags & TIMESRFLAG ? YES : NO);
    self.reminderEnabled = ( flags & ENABLEFLAG ? YES : NO );
    self.untilEnabled = (flags & UNTILFLAG ? YES : NO );
    self.fromLast = (flags & FROMLASTFLAG ? YES : NO );
}

- (void) loadRid:(NSString*)sqlWhere to:(trackerObj*)to {
    NSString *sql = [NSString stringWithFormat:@"select rid, monthDays, weekDays, everyMode, everyVal, start, until, times, flags, tid, vid, saveDate, msg from reminders where %@",sqlWhere];
    int arr[12];
    unsigned int flags=0;
    NSString *tmp = [to toQry2I12aS1:arr sql:sql];
    //DBGLog(@"read msg: %@",tmp);
    if (0 != arr[0]) {   // && (arr[0] != self.rid)) {
        self.rid = arr[0];
        self.monthDays = arr[1];
        self.weekDays = arr[2];
        self.everyMode = arr[3];
        self.everyVal = arr[4];
        self.start = arr[5];
        self.until = arr[6];
        self.times = arr[7];
        flags = arr[8];
        self.tid = arr[9];
        self.vid = arr[10];
        self.saveDate = arr[11];
        
        [self putFlags:flags];
        
        self.msg = tmp;
        sql = [NSString stringWithFormat:@"select soundFileName from reminders where %@",sqlWhere];
        self.soundFileName = [to toQry2Str:sql];
        if ([@"(null)" isEqualToString:self.soundFileName]) {
            self.soundFileName=nil;
        }
        
    } else {
        [self clearNR];
        self.rid = 0;
        self.saveDate = (int) [[NSDate date] timeIntervalSince1970];
        self.msg = to.trackerName;
        self.tid = to.toid;
    }
  
    //sql = nil;

    DBGLog(@"%@",self);
}

- (NSDictionary*) dictFromNR {
    unsigned int flags = [self getFlags];
    return @{
            @"rid": @(self.rid),
            @"monthDays": @(self.monthDays),
            @"weekDays": @(self.weekDays),
            @"everyMode": @(self.everyMode),
            @"everyVal": @(self.everyVal),
            @"start": @(self.start),
            @"until": @(self.until),
            @"times": @(self.times),
            @"msg": self.msg,
            @"soundFile": (self.soundFileName ? self.soundFileName : @""),
            @"flags": @(flags),
            @"tid": @(self.tid),
            @"vid": @(self.vid),
            @"saveDate": @(self.saveDate)
            };
}


- (void) clearNR {
    //self.rid=0; // need to keep if set
    self.monthDays=0;
    self.weekDays=0;
    self.everyMode=0;
    self.everyVal=0;
    self.start = (7 * 60);
    self.until = (23 * 60);
    self.untilEnabled = NO;
    self.times = 0;
    //if (nil != to) {
    //    self.msg = to.trackerName;
    //    self.tid = to.toid;
    //} else {
        self.msg = nil;
        self.tid = 0;
    //}
    //self.soundFileName=nil;
    self.timesRandom = NO;
    self.reminderEnabled = YES;
    self.untilEnabled = NO;
    self.fromLast = NO; 
    self.vid = 0;
    //self.saveDate=0;  // need to keep if set
}

-(NSInteger) hrVal:(NSInteger)val {
    return val/60;
}

-(NSInteger) mnVal:(NSInteger)val {
    return val % 60;
}



-(NSString*)timeStr:(NSInteger)val {
    if (-1 == val) {
        return @"-";
    }
    return [NSString stringWithFormat:@"%02ld:%02ld",(long)[self hrVal:val],(long)[self mnVal:val]];
}

- (NSString*) description {
    NSString *desc = [NSString stringWithFormat:@"nr:%ld ",(long)self.rid];

    if (self.start > -1) {
        desc = [desc stringByAppendingString:[NSString stringWithFormat:@"start %@ ",[self timeStr:self.start]]];
    }
    
    if (self.untilEnabled) {
        desc = [desc stringByAppendingString:[NSString stringWithFormat:@"until %@ ",[self timeStr:self.until]]];
    }
    
    if (self.monthDays) {
        int i;
        NSMutableArray *nma = [[NSMutableArray alloc] initWithCapacity:32];
        for (i=0;i<32;i++) {
            if (self.monthDays & (0x01 << i)) {
                [nma addObject:[NSString stringWithFormat:@"%d",i+1]];
            }
        }
        desc = [desc stringByAppendingString:[NSString stringWithFormat:@"monthDays:%@ ",[nma componentsJoinedByString:@","]]];

    } else if (self.everyVal) {

        switch (self.everyMode) {
            case EV_HOURS:
                desc = [desc stringByAppendingString:[NSString stringWithFormat:@"every %ld Hours ",(long)self.everyVal]];
                break;
            case EV_DAYS:
                desc = [desc stringByAppendingString:[NSString stringWithFormat:@"every %ld Days ",(long)self.everyVal]];
                break;
            case EV_WEEKS:
                desc = [desc stringByAppendingString:[NSString stringWithFormat:@"every %ld Weeks ",(long)self.everyVal]];
                break;
            case EV_MONTHS:
                desc = [desc stringByAppendingString:[NSString stringWithFormat:@"every %ld Months ",(long)self.everyVal]];
                break;
            default:   // EV_MINUTES
                desc = [desc stringByAppendingString:[NSString stringWithFormat:@"every %ld Minutes ",(long)self.everyVal]];
                break;
        }
        
        if (self.fromLast) {
            if (self.vid) {
                desc = [desc stringByAppendingString:[NSString stringWithFormat:@"from last vid:%ld ",(long)self.vid]];
            } else {
                desc = [desc stringByAppendingString:[NSString stringWithFormat:@"from last tracker:%ld ",(long)self.tid]];
            }
        }


    } else {   // if (self.nr.weekDays)  = default if nothing set
        desc = [desc stringByAppendingString:@"weekdays: "];
        
        NSUInteger weekdays[7];
        NSUInteger firstWeekDay;
        firstWeekDay = [[NSCalendar currentCalendar] firstWeekday];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSString *wdNames[7];
        
        int i;
        for (i=0;i<7;i++) {
            NSUInteger wd = firstWeekDay +i;
            if (wd > 7) {
                wd -= 7;
            }
            weekdays[i] = wd-1;  // firstWeekDay is 1-indexed, switch to 0-indexed
            wdNames[i] = [dateFormatter shortWeekdaySymbols][weekdays[i]];
        }
        
        for (i=0;i<7;i++) {
            if ((BOOL) (0 != (self.weekDays & (0x01 << weekdays[i])))) {
                desc = [desc stringByAppendingString:[NSString stringWithFormat:@"%@ ",wdNames[i]]];
            }
        }
    }

    desc = [desc stringByAppendingString:[NSString stringWithFormat:@"msg:'%@' ",self.msg]];
    desc = [desc stringByAppendingString:[NSString stringWithFormat:@"saveDate:'%@' ",[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval) self.saveDate]]];

    if (nil == self.soundFileName) {
        desc = [desc stringByAppendingString:@"default sound "];
    } else {
        desc = [desc stringByAppendingString:[NSString stringWithFormat:@"soundfile %@ ",self.soundFileName]];
    }
    
    if (self.reminderEnabled) {
        desc = [desc stringByAppendingString:@"enabled"];
    } else {
        desc = [desc stringByAppendingString:@"disabled"];
    }

    return desc;
}

-(void) create {
    if (nil == self.notifContent) {
        if (nil == (self.notifContent = [UNMutableNotificationContent new])) {
            return;
        }
    }
    
    
    //self.notifContent.timeZone = [NSTimeZone defaultTimeZone];
    
    self.notifContent.body = self.msg;
    self.notifContent.title = NSLocalizedString(@"rTracker reminder", nil);
    
    self.notifContent.badge = [NSNumber numberWithInt:1];
    
    if (nil == self.soundFileName || [@"" isEqualToString:self.soundFileName]) {
        self.notifContent.sound = UNNotificationSound.defaultSound;
    } else {
        self.notifContent.sound = [UNNotificationSound soundNamed:self.soundFileName];
    }
    self.notifContent.launchImageName = [rTracker_resource getLaunchImageName];
    
    //NSDictionary *infoDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:self.tid] forKey:@"tid"];
    NSDictionary *infoDict = @{@"tid": @(self.tid),@"rid": @(self.rid)};
    self.notifContent.userInfo = infoDict;
    DBGLog(@"created.");
}

-(void) cancelOld {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    NSArray *idArr = [NSArray arrayWithObject:[NSString stringWithFormat:@"%ld", (long) self.rid]];
    [center removePendingNotificationRequestsWithIdentifiers:idArr];
}

-(void) schedule:(NSDate*) targDate {
    [self cancelOld];  // remove any notifications set with rid instead of tid-rid
    if (nil == self.notifContent)
        [self create];
    if (nil == self.notifContent)
        return;
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
      if (settings.authorizationStatus != UNAuthorizationStatusAuthorized) {
          return; // Notifications not allowed
      }
    }];
    
    NSString *idStr = [NSString stringWithFormat:@"%ld-%ld", (long) self.tid, (long) self.rid];
    
    NSDateComponents *triggerDate = [[NSCalendar currentCalendar]
                                     components:NSCalendarUnitYear +
                                     NSCalendarUnitMonth + NSCalendarUnitDay +
                                     NSCalendarUnitHour + NSCalendarUnitMinute +
                                     NSCalendarUnitSecond fromDate:targDate];
    
    UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:triggerDate repeats:NO];

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:idStr content:self.notifContent trigger:trigger];

    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
      if (error != nil) {
        DBGWarn(@"error scheduling reminder %@: %@",idStr, error);
      }
    }];
    
    DBGLog(@"scheduled %@", idStr);
}

-(void) playSound {
    [rTracker_resource playSound:self.soundFileName];
}


+(void) useRidArray:(UNUserNotificationCenter*) center tid:(NSInteger) tid callback:(void (^)(NSMutableArray *)) callback {
    __block NSMutableArray *ridArray = [[NSMutableArray alloc] init];
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray *notifications) {
        for (int i=0;
             i<[notifications count];
             i++)
        {
            UNNotificationRequest *oneEvent = notifications[i];
            NSDictionary *userInfoCurrent = oneEvent.content.userInfo;
            if ([userInfoCurrent[@"tid"] integerValue] == tid) {
                NSArray *tidRid = [oneEvent.identifier componentsSeparatedByString:@"-"];
                [ridArray addObject:tidRid[1]];  // just add rid
            }
        }
        callback(ridArray);
    }];
    
}

@end
