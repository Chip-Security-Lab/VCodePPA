//SystemVerilog
// 顶层模块
module crc_hybrid #(parameter WIDTH=32)(
    input clk, rst_n, en,
    input [WIDTH-1:0] data,
    output [31:0] crc
);
    // 定义流水线阶段信号
    wire [31:0] data_stage1;
    reg [31:0] data_stage2;
    wire [31:0] processed_data_stage2;
    reg [31:0] processed_data_stage3;
    
    // 阶段1: 数据接口 - 处理输入数据提取
    data_interface #(
        .WIDTH(WIDTH)
    ) data_interface_inst (
        .data_in(data),
        .data_out(data_stage1)
    );
    
    // 阶段1到阶段2的流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 32'h0;
        end else if (en) begin
            data_stage2 <= data_stage1;
        end
    end
    
    // 阶段2: CRC计算核心 - 实现CRC算法
    crc_computation_core crc_computation_inst (
        .data_in(data_stage2),
        .width_param(WIDTH),
        .processed_data(processed_data_stage2)
    );
    
    // 阶段2到阶段3的流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processed_data_stage3 <= 32'h0;
        end else if (en) begin
            processed_data_stage3 <= processed_data_stage2;
        end
    end
    
    // 阶段3: 输出寄存器
    crc_output_stage output_stage_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .processed_data(processed_data_stage3),
        .crc_out(crc)
    );
endmodule

// 数据接口模块 - 优化后
module data_interface #(parameter WIDTH=32)(
    input [WIDTH-1:0] data_in,
    output [31:0] data_out
);
    // 数据提取逻辑
    // 对于任何宽度的输入，只取低32位
    assign data_out = (WIDTH >= 32) ? data_in[31:0] : {{(32-WIDTH){1'b0}}, data_in};
endmodule

// CRC计算核心模块 - 拆分长路径，优化组合逻辑
module crc_computation_core (
    input [31:0] data_in,
    input [31:0] width_param,
    output [31:0] processed_data
);
    // CRC多项式常量
    localparam CRC_POLYNOMIAL = 32'h04C11DB7;
    
    // 简化判断逻辑
    wire is_wide_mode = (width_param > 32);
    
    // 优化的CRC计算逻辑，拆分路径深度
    wire [31:0] shifted_data = {data_in[30:0], 1'b0};
    wire [31:0] xor_mask = data_in[31] ? CRC_POLYNOMIAL : 32'h0;
    wire [31:0] wide_mode_result = shifted_data ^ xor_mask;
    
    // 最终选择 - 使用三元运算符
    assign processed_data = is_wide_mode ? wide_mode_result : data_in;
endmodule

// 输出寄存器模块 - 替代原时序控制器
module crc_output_stage (
    input clk,
    input rst_n,
    input en,
    input [31:0] processed_data,
    output reg [31:0] crc_out
);
    // 简化的输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_out <= 32'h0;
        end else if (en) begin
            crc_out <= processed_data;
        end
    end
endmodule