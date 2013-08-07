//
//  DEShell.m
//  DevEnvironment
//
//  Created by Evan Coleman on 7/26/13.
//  Copyright (c) 2013 Evan Coleman. All rights reserved.
//

#import "DEShell.h"

#define kHelpCommand @[@"help", @"?"]
#define kStartCommand @[@"start", @"s"]
#define kExitCommand @[@"quit", @"exit", @"q", @"stop"]
#define kLogCommand @[@"log", @"tail", @"l", @"t"]

#define kCommandKey @"command"
#define kArgsKey @"args"
#define kTaskKey @"task"
#define kPipeKey @"pipe"

@interface DEShell ()

@property (nonatomic, strong) NSArray *commandsToRun;

@end

@implementation DEShell

+ (void)beginShell {
    (void)[[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.commandsToRun = @[[self dictWithCommand:@"/usr/local/Cellar/postgresql/9.2.4/bin/postgres" andArgs:@[@"-D", @"/usr/local/var/postgres"]],
                               [self dictWithCommand:@"/usr/local/opt/memcached/bin/memcached" andArgs:@[]],
                               [self dictWithCommand:@"/usr/local/opt/mongodb/mongod" andArgs:@[@"run", @"--config", @"/usr/local/etc/mongod.conf"]],
                               [self dictWithCommand:@"/usr/local/opt/redis/bin/redis-server" andArgs:@[@"/usr/local/etc/redis.conf"]]];
        
        [self beginShell];
    }
    return self;
}

- (void)beginShell {
    BOOL flag = YES;
    while (flag) {
        printf("Enter a command:\n");
        char input[50];
        scanf(" %[^\t\n]", input);
        NSArray *args = [[NSString stringWithUTF8String:input] componentsSeparatedByString:@" "];
        NSString *command = args[0];
        
        if ([kHelpCommand containsObject:command]) {
            [self showHelp];
        } else if ([kStartCommand containsObject:command]) {
            [self startCommands];
        } else if ([kExitCommand containsObject:command]) {
            [self endCommands];
            flag = NO;
        } else if ([kLogCommand containsObject:command]) {
            if ([args count] > 1) {
                [self logCommand:args[1]];
            } else {
                [self showLogHelp];
            }
        }
    }
}

- (void)startCommands {
    for (NSMutableDictionary *dict in self.commandsToRun) {
        NSString *command = dict[kCommandKey];
        NSArray *args = dict[kArgsKey];
        
        printf("Starting %s...\n", [[[command pathComponents] lastObject] UTF8String]);
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:command];
        [task setArguments:args];
        
        dict[kTaskKey] = task;
        
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardInput:pipe];
        [task setStandardOutput:pipe];
        [task setStandardError:pipe];
        
        dict[kPipeKey] = pipe;
        
        [task launch];
    }
}

- (void)endCommands {
    for (NSMutableDictionary *dict in self.commandsToRun) {
        NSTask *task = dict[kTaskKey];
        
        printf("Stopping %s...\n", [[[dict[kCommandKey] pathComponents] lastObject] UTF8String]);
        
        [task terminate];
    }
}

- (void)logCommand:(NSString *)command {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSString *testString = [[[(NSDictionary *)evaluatedObject objectForKey:kCommandKey] pathComponents] lastObject];
        if ([testString hasPrefix:command]) {
            return YES;
        } else {
            return NO;
        }
    }];
    NSArray *matches = [self.commandsToRun filteredArrayUsingPredicate:predicate];
    if ([matches count] > 0) {
        [self tailLogsForCommand:matches[0]];
    } else {
        printf("Command '%s' not found\n", [command UTF8String]);
    }
}

- (void)showLogHelp {
    printf("Usage:\n\tlog [command]\n");
    printf("\tOnly the first few letters of the command name are required\n");
}

- (void)showHelp {
    printf("Usage:\n\tdev [command]\n\n");
    printf("Commands:\n");
    printf("\tstart   Starts all commands\n");
    printf("\tquit    Gracefully exits all commands\n");
    printf("\tlog     Tails the logs for a command\n");
}

- (void)tailLogsForCommand:(NSDictionary *)dict {
    NSTask *task = dict[kTaskKey];
    
}

- (void)spawnNewTab {
    NSAppleScript *key = [[NSAppleScript alloc] initWithSource:@"tell application \"System Events\" to keystroke \"t\" using {command down}"];
    [key executeAndReturnError:nil];
}

#pragma mark - Convenience Methods

- (NSMutableDictionary *)dictWithCommand:(NSString *)command andArgs:(NSArray *)args {
    return [@{kCommandKey: command, kArgsKey: args} mutableCopy];
}

@end
