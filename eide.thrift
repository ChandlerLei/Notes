/**
 * Types and Structures
 */

typedef i64 Timestamp
typedef string OrderID
typedef string CourierID
typedef string RestaurantID


/**
 * Exceptions
 */
enum EideErrorCode {
    // system error code
    UNKNOWN_ERROR = 0,
    TOO_BUSY_ERRPR = 1,

    // user error code
    PARAMS_ERROR = 1024,
}

exception EideUserException {
   1: required EideErrorCode error_code,
   2: required string error_name,
   3: optional string message,
}

exception EideSystemException {
   1: required EideErrorCode error_code,
   2: required string error_name,
   3: optional string message,
}

exception EideUnknownException {
   1: required EideErrorCode error_code,
   2: required string error_name,
   3: required string message,
}

/**
*  ADT 定义
*/

// 渠道商
enum ChannelType {
  Crowd = 1,    // 众包
  Team  = 2,    // 团队
}

// 订单类型
enum OrderType {
    Normal = 1,  // 正常订单
    Booked = 2,  // 预订单，暂无此类订单分类，目前保留该字段
}

// 订单状态
enum OrderStatusType {
  DISPATCHING = 1,   // 指派中
  PICKING = 2,       // 取餐中
  DELIVERING = 3,    // 配送中
}

enum CourierAction {
    PICK = 1,    // 取餐
    DELIVERY = 2, // 送餐
}

// 坐标系类型
enum GPSType {
    WGS84 = 1,     // 国际坐标系
    BAIDU = 2,     // 百度坐标系
    HUOXING = 3,   // 火星坐标系
}

// 地址信息
struct Location {
    1: required GPSType GPS,    // 坐标系类型
    2: required double Lat,     // 纬度
    3: required double Lng,     // 经度
    4: optional double Alt,     // 海拔高度
    5: optional string Address, // 地址描述
    6: optional string POIID,     // ELEME POI ID
}

// Order SLA
struct OrderSLA {
    1: required Timestamp PromisedAt,   // 承诺送达时间
}

// 餐厅信息
struct Restaurant {
  1: required RestaurantID RstID,       // 271808
  2: required Location RstLoc,          // 餐厅地址
  3: required i32 CookingCost,          // 218, 预估出餐等待时间, 单位秒
}

// 客户信息
struct Customer {
  1: required Location CstLoc,          // 客户地址
  2: optional i32 CstTime               // 客户送餐地等待时间, 待分配时该字段无意义
}

// 运单类
struct Order {
  1: required OrderID ID,               // 运单ID 1230912903892193
  2: required OrderType Type,           // 运单类型
  3: required Timestamp CreatedAt,      // 运单创建时间 
  4: required OrderStatusType Status,   // 订单状态
  5: required OrderSLA SLA,             // 运单SLA
  6: required Restaurant Rst,           // 餐厅信息
  7: required Customer Cst              // 客户信息
}

// 骑手实时快照数据
struct CourierOnlineData {
  1: required Location Loc,                 // 最近一次位置
  2: required list<Order> Orders,           // 骑手所背订单[]
}

// 骑手离线学习数据
struct CourierOfflineData {
  1: required double Speed,                 // 速度m/s
  2: required i32 MaxLoads,                 // 最大负载量
}

// 骑手类
struct Courier {
  1: required CourierID ID,
  2: required CourierOnlineData OnlineData,   // 在线数据 
  3: required CourierOfflineData OfflineData, // 离线数据
}

// 订单骑手映射关系
struct OrderCourierMap {
    1: required CourierID CID,           // 骑手ID
    2: required OrderID OID,             // 订单ID
    3: optional i32 DstDeliveryTime      // 送餐厅等待时间
}

// 路线节点
struct RouteNode {
  1: required OrderID ID,            // 路由节点对应的订单 
  2: required CourierAction Action,  // 对订单的操作, 取/送
  3: required Timestamp FinishTime,               // 操作预计完成时刻
}

// 调度计划
struct Plan {
  1: required CourierID CourierID,                // 骑手ID  
  2: required list<RouteNode> RoutingSequence,    // 路线规划序列, 有序
  3: optional i32 DeltaCost,                      // 新增订单额外增加的代价
  4: required i32 TotalCost,                      // 总代价
}
/**
 * API
 */
service EideService {
    // 功能: 服务健康检查
    bool ping()
        throws (1: EideUserException user_exception,
                2: EideSystemException system_exception,
                3: EideUnknownException unknown_exception,)

    // 功能: 分配订单
    // 参数: Order, 待分配新订单
    //       Courier, 待分配骑手候选人，len(couriers) <= 200
    // 返回: 调度计划, list有序. 越靠前越好.
    list<Plan> Schedule(1: ChannelType Channel, 2: Order order, 3: list<Courier> couriers, 4: list<OrderCourierMap> ocm)
        throws (1: EideUserException user_exception,
                2: EideSystemException system_exception,
                3: EideUnknownException unknown_exception,)

    // 功能: 重新规划路线
    // 参数: Courier, 待规划骑手路线
    // 返回: 新的调度路线计划
    Plan Routing(1: ChannelType Channel, 2: Courier courier)
        throws (1: EideUserException user_exception,
                2: EideSystemException system_exception,
                3: EideUnknownException unknown_exception,)
}
