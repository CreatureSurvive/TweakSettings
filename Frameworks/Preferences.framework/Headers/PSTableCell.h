#import <UIKit/UITableViewCell.h>

@class PSSpecifier;

typedef enum : NSUInteger {
	PSGroupCell,
	PSLinkCell,
	PSLinkListCell,
	PSListItemCell,
	PSTitleValueCell,
	PSSliderCell,
	PSSwitchCell,
	PSStaticTextCell,
	PSEditTextCell,
	PSSegmentCell,
	PSGiantIconCell,
	PSGiantCell,
	PSSecureEditTextCell,
	PSButtonCell,
	PSEditTextViewCell,
	PSSpinnerCell
} PSCellType;

@interface PSTableCell : UITableViewCell

+ (PSCellType)cellTypeFromString:(NSString *)cellType;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier;

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier;

- (void)setSeparatorStyle:(UITableViewCellSeparatorStyle)style;

@property (nonatomic, retain) PSSpecifier *specifier;
@property (nonatomic) PSCellType type;
@property (nonatomic, retain) id target;
@property (nonatomic) SEL action;

@property (nonatomic, retain) id cellTarget;
@property (nonatomic) SEL cellAction;

@property (nonatomic) BOOL cellEnabled;

@property (nonatomic, retain) UIImage *icon;

- (UIImage *)getLazyIcon;

@property (nonatomic, retain, readonly) UIImage *blankIcon;
@property (nonatomic, retain, readonly) NSString *lazyIconAppID;

@property (nonatomic, retain, readonly) UILabel *titleLabel;

- (void)setValue:(id)arg1;

@end
