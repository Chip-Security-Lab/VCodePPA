//SystemVerilog
// 顶层模块 - 负边沿移位寄存器控制器
module neg_edge_shifter #(
    parameter LENGTH = 6
)(
    input  wire             neg_clk,
    input  wire             d_in,
    input  wire             rstn,
    output wire [LENGTH-1:0] q_out
);
    
    // 内部连线
    wire shift_enable;
    wire [LENGTH-1:0] shift_data;
    
    // 控制单元实例化
    shifter_control_unit control_unit (
        .neg_clk     (neg_clk),
        .rstn        (rstn),
        .shift_enable(shift_enable)
    );
    
    // 数据路径单元实例化
    shifter_datapath #(
        .LENGTH(LENGTH)
    ) datapath_unit (
        .neg_clk     (neg_clk),
        .d_in        (d_in),
        .rstn        (rstn),
        .shift_enable(shift_enable),
        .q_out       (q_out)
    );
    
endmodule

//------------------------------------------------------
// 控制单元 - 处理使能信号
//------------------------------------------------------
module shifter_control_unit (
    input  wire neg_clk,
    input  wire rstn,
    output wire shift_enable
);
    
    // 在复位无效时总是允许移位操作
    assign shift_enable = rstn;
    
endmodule

//------------------------------------------------------
// 数据路径单元 - 处理实际的移位寄存器逻辑
//------------------------------------------------------
module shifter_datapath #(
    parameter LENGTH = 6
)(
    input  wire             neg_clk,
    input  wire             d_in,
    input  wire             rstn,
    input  wire             shift_enable,
    output wire [LENGTH-1:0] q_out
);
    
    // 移位寄存器核心逻辑
    shifter_core #(
        .LENGTH(LENGTH)
    ) shift_reg_core (
        .neg_clk     (neg_clk),
        .d_in        (d_in),
        .rstn        (rstn),
        .shift_enable(shift_enable),
        .shift_out   (q_out)
    );
    
endmodule

//------------------------------------------------------
// 移位寄存器核心 - 实现实际的移位操作
//------------------------------------------------------
module shifter_core #(
    parameter LENGTH = 6
)(
    input  wire             neg_clk,
    input  wire             d_in,
    input  wire             rstn,
    input  wire             shift_enable,
    output wire [LENGTH-1:0] shift_out
);
    
    (* shreg_extract = "yes" *)  // 指示综合工具使用专用的移位寄存器资源
    reg [LENGTH-1:0] shift_reg;
    
    // 移位寄存器逻辑
    always @(negedge neg_clk or negedge rstn) begin
        if (!rstn)
            shift_reg = {LENGTH{1'b0}};
        else if (shift_enable)
            shift_reg = {d_in, shift_reg[LENGTH-1:1]};
    end
    
    // 输出赋值
    assign shift_out = shift_reg;
    
endmodule