//SystemVerilog
//IEEE 1364-2005 Verilog标准

///////////////////////////////////////////////////////////////////////////////
// 顶层模块：程序范围解码器 
///////////////////////////////////////////////////////////////////////////////
module program_range_decoder #(
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [ADDR_WIDTH-1:0] base_addr,
    input wire [ADDR_WIDTH-1:0] limit,
    output wire in_range
);
    // 内部连接信号
    wire addr_ge_base;      // 地址大于等于基址
    wire addr_lt_upper;     // 地址小于上限
    wire [ADDR_WIDTH-1:0] upper_bound; // 上界值

    // 计算上限地址
    addr_boundary_calculator #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_boundary_calc (
        .base_addr(base_addr),
        .limit(limit),
        .upper_bound(upper_bound)
    );

    // 地址范围比较器
    addr_comparator #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_addr_comp (
        .addr(addr),
        .base_addr(base_addr),
        .upper_bound(upper_bound),
        .addr_ge_base(addr_ge_base),
        .addr_lt_upper(addr_lt_upper)
    );

    // 范围判断逻辑
    range_validator u_range_valid (
        .addr_ge_base(addr_ge_base),
        .addr_lt_upper(addr_lt_upper),
        .in_range(in_range)
    );
endmodule

///////////////////////////////////////////////////////////////////////////////
// 地址边界计算模块
///////////////////////////////////////////////////////////////////////////////
module addr_boundary_calculator #(
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] base_addr,
    input wire [ADDR_WIDTH-1:0] limit,
    output wire [ADDR_WIDTH-1:0] upper_bound
);
    // 计算上界值 = 基址 + 限制值
    assign upper_bound = base_addr + limit;
endmodule

///////////////////////////////////////////////////////////////////////////////
// 地址比较器模块
///////////////////////////////////////////////////////////////////////////////
module addr_comparator #(
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [ADDR_WIDTH-1:0] base_addr,
    input wire [ADDR_WIDTH-1:0] upper_bound,
    output wire addr_ge_base,
    output wire addr_lt_upper
);
    // 优化的比较逻辑，使用原生比较运算以提高性能
    assign addr_ge_base = (addr >= base_addr);
    assign addr_lt_upper = (addr < upper_bound);
endmodule

///////////////////////////////////////////////////////////////////////////////
// 范围验证模块
///////////////////////////////////////////////////////////////////////////////
module range_validator (
    input wire addr_ge_base,
    input wire addr_lt_upper,
    output wire in_range
);
    // 范围有效条件：地址大于等于基址 且 地址小于上限
    assign in_range = addr_ge_base && addr_lt_upper;
endmodule