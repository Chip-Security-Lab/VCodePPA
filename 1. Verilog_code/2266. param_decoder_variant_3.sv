//SystemVerilog
module param_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16
)(
    input wire clk,                    // 时钟信号
    input wire rst_n,                  // 复位信号（低有效）
    input wire [ADDR_WIDTH-1:0] address,
    input wire enable,
    input wire valid_in,               // 输入数据有效信号
    output reg valid_out,              // 输出数据有效信号
    output wire ready_out,             // 流水线就绪信号
    output reg [OUT_WIDTH-1:0] select
);
    // 流水线阶段控制信号
    reg valid_stage1, valid_stage2;
    wire ready_stage1, ready_stage2;
    
    // 数据流水线寄存器
    reg [ADDR_WIDTH-1:0] address_stage1;
    reg enable_stage1;
    reg [OUT_WIDTH-1:0] decode_stage2;
    reg enable_stage2;
    
    // 后级就绪则前级也就绪
    assign ready_stage2 = 1'b1;         // 输出级始终就绪
    assign ready_stage1 = ready_stage2;  // 级联就绪信号
    assign ready_out = ready_stage1;     // 输入级就绪信号
    
    // 阶段1：输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            address_stage1 <= {ADDR_WIDTH{1'b0}};
            enable_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (ready_stage1) begin
            address_stage1 <= address;
            enable_stage1 <= enable;
            valid_stage1 <= valid_in;
        end
    end
    
    // 阶段2：解码计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_stage2 <= {OUT_WIDTH{1'b0}};
            enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (ready_stage2) begin
            // 提前计算基础解码数据
            decode_stage2 <= (1'b1 << address_stage1);
            enable_stage2 <= enable_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3：输出选择逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select <= {OUT_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            // 使用与门替代条件选择，减少多路选择器延迟
            select <= enable_stage2 ? decode_stage2 : {OUT_WIDTH{1'b0}};
            valid_out <= valid_stage2;
        end
    end

endmodule