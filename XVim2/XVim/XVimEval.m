//
//  XVimEval.m
//  XVim
//
//  Created by pebble on 2013/01/28.
//
//

#import "XVimEval.h"
#import "Logger.h"
#import "SourceEditorViewProtocol.h"
#import "XVimWindow.h"
#import "XVim2-Swift.h"

@implementation XVimEval
- (id)init
{
    self = [super init];
    if (self) {
        let func = [[XVimEvalFunc alloc] initWithFuncName:@"line" methodName:@"line:inWindow:"];
        _evalFuncs = @[func];
    }
    return self;
}

- (void)evaluateWhole:(nonnull XVimEvalArg*)args inWindow:(nonnull XVimWindow*)window
{
    // parse
    // 1) support only string
    // 2) support only string concatenation
    var instr = args.invar;
    var evaled = [NSMutableString stringWithFormat:@""];
    NSUInteger index = 0;
    var concat = FALSE;
    while (index < instr.length) {
        unichar uc = [instr characterAtIndex:index];
        if (uc == '"') {
            // double quatation string : "abc.."
            ++index;
            while (index < instr.length) {
                unichar uc2 = [instr characterAtIndex:index];
                if (uc2 == '"') {
                    ++index;
                    break;
                }
                [evaled appendFormat:@"%C", uc2];
                ++index;
            }
        }
        else if (uc == ' ') {
            // space
            ++index;
        }
        else if (uc == '.') {
            // period
            concat = TRUE;
            ++index;
        }
        else {
            // begin function
            var cmd = [NSMutableString stringWithFormat:@""];
            while (index < instr.length) {
                unichar uc2 = [instr characterAtIndex:index];
                if (uc2 == ')') {
                    [cmd appendFormat:@"%C", uc2];
                    ++index;
                    break;
                }
                [cmd appendFormat:@"%C", uc2];
                ++index;
            }
            var evalarg = [[XVimEvalArg alloc] init];
            evalarg.invar = cmd;
            [self evaluateFunc:evalarg inWindow:window];
            var ret = evalarg.rvar;
            if (concat) {
                if (ret != nil) {
                    [evaled appendString:ret];
                }
                concat = FALSE;
            }
        }
    }
    args.rvar = [NSString stringWithFormat:@"\"%@\"", evaled];
}

- (void)evaluateFunc:(XVimEvalArg*)evalarg inWindow:(XVimWindow*)window
{
    evalarg.rvar = nil;

    // switch on function name
    for (XVimEvalFunc* evalfunc in _evalFuncs) {
        if ([evalarg.invar hasPrefix:evalfunc.funcName]) {
            SEL sel = NSSelectorFromString(evalfunc.methodName);
            if ([self respondsToSelector:sel]) {
                XVimEvalArg* evalarg_func = [[XVimEvalArg alloc] init];
                NSString* str = [evalarg.invar substringFromIndex:evalfunc.funcName.length];
                if (str.length > 2
                    && ([str characterAtIndex:0] == '(' && [str characterAtIndex:str.length - 1] == ')')) {
                    evalarg_func.invar = [NSString
                                stringWithFormat:@"%@", [str substringWithRange:NSMakeRange(1, str.length - 2)]];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [self performSelector:sel withObject:evalarg_func withObject:window];
#pragma clang diagnostic pop
                    evalarg.rvar = evalarg_func.rvar;
                }
                else {
                    // have no "()"
                }
                break;
            }
        }
    }
}

// each function implementation below
- (void)line:(XVimEvalArg*)evalarg inWindow:(XVimWindow*)window
{
    evalarg.rvar = nil;
    // support only "."
    if ([evalarg.invar isEqualToString:@"\".\""]) {
        evalarg.rvar = [NSString stringWithFormat:@"%ld", (long)window.sourceView.currentLineNumber];
    }
}

@end
