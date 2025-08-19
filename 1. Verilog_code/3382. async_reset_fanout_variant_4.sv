//SystemVerilog
//IEEE 1364-2005
// 顶层模块
module async_reset_fanout (
    input  wire        async_rst_in,
    input  wire        req_in,         // 请求信号输入
    input  wire [15:0] data_in,        // 数据输入
    output wire        ack_out,        // 应答信号输出
    output wire [15:0] data_out,       // 数据输出
    output wire [15:0] rst_out
);
    wire [3:0] rst_group;
    reg  ack_reg;
    reg  [15:0] data_reg;
    
    // 实例化第一级扇出子模块
    async_reset_stage1 rst_stage1 (
        .rst_in  (async_rst_in),
        .rst_out (rst_group)
    );
    
    // 实例化第二级扇出子模块
    async_reset_stage2 rst_stage2_0 (
        .grp_rst_in  (rst_group[0]),
        .grp_rst_out (rst_out[3:0])
    );
    
    async_reset_stage2 rst_stage2_1 (
        .grp_rst_in  (rst_group[1]),
        .grp_rst_out (rst_out[7:4])
    );
    
    async_reset_stage2 rst_stage2_2 (
        .grp_rst_in  (rst_group[2]),
        .grp_rst_out (rst_out[11:8])
    );
    
    async_reset_stage2 rst_stage2_3 (
        .grp_rst_in  (rst_group[3]),
        .grp_rst_out (rst_out[15:12])
    );
    
    // 请求-应答握手接口逻辑
    always @(posedge req_in or posedge async_rst_in) begin
        if (async_rst_in) begin
            ack_reg <= 1'b0;
            data_reg <= 16'h0000;
        end else if (req_in) begin
            ack_reg <= 1'b1;
            data_reg <= data_in;
        end else begin
            ack_reg <= 1'b0;
        end
    end
    
    assign ack_out = ack_reg;
    assign data_out = data_reg;
    
endmodule

// 第一级扇出模块 - 1到4扇出
module async_reset_stage1 (
    input  wire       rst_in,
    output wire [3:0] rst_out
);
    // 参数化设计，便于将来可能的修改
    parameter FANOUT_WIDTH = 4;
    
    // 使用连续赋值进行扇出
    assign rst_out = {FANOUT_WIDTH{rst_in}};
    
endmodule

// 第二级扇出模块 - 1到4扇出
module async_reset_stage2 (
    input  wire       grp_rst_in,
    output wire [3:0] grp_rst_out
);
    // 参数化设计，便于将来可能的修改
    parameter GROUP_WIDTH = 4;
    
    // 使用连续赋值进行扇出
    assign grp_rst_out = {GROUP_WIDTH{grp_rst_in}};
    
endmodule