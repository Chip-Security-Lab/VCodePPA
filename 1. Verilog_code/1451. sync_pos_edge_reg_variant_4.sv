//SystemVerilog
//IEEE 1364-2005 Verilog标准
// 顶层模块 - 增加流水线级数的同步正边沿寄存器
module sync_pos_edge_reg #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire load_en,
    output wire [DATA_WIDTH-1:0] data_out
);
    // 内部连线
    wire [DATA_WIDTH-1:0] next_data_stage1;
    wire [DATA_WIDTH-1:0] next_data_stage2;
    wire load_en_stage1;
    
    // 实例化增强型控制逻辑模块
    enhanced_control_logic #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_enhanced_control_logic (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .load_en(load_en),
        .next_data_stage1(next_data_stage1),
        .next_data_stage2(next_data_stage2),
        .load_en_stage1(load_en_stage1)
    );
    
    // 实例化增强型寄存器模块
    enhanced_register_unit #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_enhanced_register_unit (
        .clk(clk),
        .rst_n(rst_n),
        .next_data_stage1(next_data_stage1),
        .next_data_stage2(next_data_stage2),
        .load_en_stage1(load_en_stage1),
        .data_out(data_out)
    );
    
endmodule

// 增强型控制逻辑模块 - 分为两个流水线级别
module enhanced_control_logic #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire load_en,
    output reg [DATA_WIDTH-1:0] next_data_stage1,
    output reg [DATA_WIDTH-1:0] next_data_stage2,
    output reg load_en_stage1
);
    // 第一级流水线 - 初步处理输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_data_stage1 <= {DATA_WIDTH{1'b0}};
            load_en_stage1 <= 1'b0;
        end
        else begin
            next_data_stage1 <= data_in;
            load_en_stage1 <= load_en;
        end
    end
    
    // 第二级流水线 - 完成数据选择逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_data_stage2 <= {DATA_WIDTH{1'b0}};
        end
        else begin
            next_data_stage2 <= load_en_stage1 ? next_data_stage1 : {DATA_WIDTH{1'b0}};
        end
    end
    
endmodule

// 增强型寄存器单元模块 - 分为多级流水线，提高时钟频率
module enhanced_register_unit #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] next_data_stage1,
    input wire [DATA_WIDTH-1:0] next_data_stage2,
    input wire load_en_stage1,
    output reg [DATA_WIDTH-1:0] data_out
);
    // 中间寄存器
    reg [DATA_WIDTH-1:0] data_intermediate;
    
    // 第一级输出缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_intermediate <= {DATA_WIDTH{1'b0}};
        else
            data_intermediate <= next_data_stage2;
    end
    
    // 第二级输出缓冲 - 最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {DATA_WIDTH{1'b0}};
        else
            data_out <= data_intermediate;
    end
    
endmodule