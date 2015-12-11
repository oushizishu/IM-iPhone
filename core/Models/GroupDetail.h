//
//  GroupDetail.h
//
//  Created by wangziliang on 15/12/4.
//
//

#import "MTLModel.h"
#import "BJIMConstants.h"

@interface GroupFile : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) int64_t fileId;
@property (nonatomic, assign) int64_t storage_id;
@property (nonatomic, assign) int64_t user_role;
@property (nonatomic, assign) int64_t user_id;
@property (nonatomic, assign) int64_t filesize;
@property (nonatomic, strong) NSString *user_name;
@property (nonatomic, strong) NSString *file_url;
@property (nonatomic, strong) NSString *file_type;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *info;
@property (nonatomic, strong) NSString *create_time;
@property (nonatomic, assign) BOOL show_delete;
@property (nonatomic, assign) BOOL support_preview;

@end

@interface GroupListFile : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) int64_t page_size;
@property (nonatomic, assign) int64_t total;
@property (nonatomic, strong) NSArray<GroupFile *> *list;

@end

@interface GroupTeacher : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, assign) int64_t is_admin;
@property (nonatomic, assign) int64_t is_major;
@property (nonatomic, assign) int64_t msg_status;
@property (nonatomic, assign) int64_t push_status;
@property (nonatomic, assign) int64_t user_id;
@property (nonatomic, assign) int64_t user_role;
@property (nonatomic, strong) NSString *user_name;
@property (nonatomic, assign) int64_t user_number;

@end

@interface GroupDetailMember : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, assign) int64_t is_admin;
@property (nonatomic, assign) int64_t is_major;
@property (nonatomic, assign) int64_t msg_status;
@property (nonatomic, assign) int64_t push_status;
@property (nonatomic, assign) int64_t user_id;
@property (nonatomic, assign) int64_t user_role;
@property (nonatomic, strong) NSString *user_name;
@property (nonatomic, assign) int64_t user_number;

@end

@interface GroupNotice : MTLModel<MTLJSONSerializing>

@property (nonatomic ,strong) NSString *content;
@property (nonatomic ,strong) NSString *creator;
@property (nonatomic, assign) int64_t noticeId;
@property (nonatomic, assign) int64_t user_id;
@property (nonatomic, assign) int64_t user_role;
@property (nonatomic, strong) NSString *create_date;

@end

@interface GroupSource : MTLModel<MTLJSONSerializing>

@property (nonatomic ,strong) NSString *course;
@property (nonatomic ,strong) NSString *course_arrange;
@property (nonatomic ,strong) NSArray<GroupTeacher *> *major_teacher_list;

@end

@interface GroupDetail : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) int64_t group_id;
@property (nonatomic, strong) NSString *group_name;
@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, assign) int64_t create_time;
@property (nonatomic, strong) NSString *detailDescription;
@property (nonatomic, assign) int64_t maxusers;
@property (nonatomic, assign) int64_t membercount;
@property (nonatomic, assign) int64_t origin_avatar;
@property (nonatomic, assign) int64_t status;
@property (nonatomic, assign) int64_t user_id;
@property (nonatomic, assign) int64_t user_role;

@property (nonatomic, strong) GroupSource *group_source;
@property (nonatomic, strong) NSArray<GroupDetailMember *> *member_list;
@property (nonatomic, strong) GroupNotice *notice;

@end
