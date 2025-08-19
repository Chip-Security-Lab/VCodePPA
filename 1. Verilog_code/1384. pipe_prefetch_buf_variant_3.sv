//SystemVerilog
// 顶层模块
module pipe_prefetch_buf #(parameter DW=32) (
    input wire clk,
    input wire en,
    input wire [DW-1:0] data_in,
    output wire [DW-1:0] data_out
);
    // 内部连线
    wire [DW-1:0] stage0_to_stage1;
    wire [DW-1:0] stage1_to_stage2;
    
    // 实例化各级流水线子模块
    pipe_stage #(
        .DW(DW),
        .STAGE_ID(0)
    ) stage0_inst (
        .clk(clk),
        .en(en),
        .data_in(data_in),
        .data_out(stage0_to_stage1)
    );
    
    // 第二级流水线使用优化的减法器
    pipe_stage_sub #(
        .DW(DW),
        .STAGE_ID(1)
    ) stage1_inst (
        .clk(clk),
        .en(en),
        .data_in(stage0_to_stage1),
        .data_out(stage1_to_stage2)
    );
    
    pipe_stage #(
        .DW(DW),
        .STAGE_ID(2)
    ) stage2_inst (
        .clk(clk),
        .en(en),
        .data_in(stage1_to_stage2),
        .data_out(data_out)
    );
endmodule

// 标准单级流水线寄存器模块
module pipe_stage #(
    parameter DW = 32,
    parameter STAGE_ID = 0
)(
    input wire clk,
    input wire en,
    input wire [DW-1:0] data_in,
    output wire [DW-1:0] data_out
);
    // 流水线寄存器
    reg [DW-1:0] stage_reg;
    
    // 时序逻辑
    always @(posedge clk) begin
        if (en) begin
            stage_reg <= data_in;
        end
    end
    
    // 输出赋值
    assign data_out = stage_reg;
endmodule

// 包含减法器的流水线阶段，使用补码加法实现减法
module pipe_stage_sub #(
    parameter DW = 32,
    parameter STAGE_ID = 0
)(
    input wire clk,
    input wire en,
    input wire [DW-1:0] data_in,
    output wire [DW-1:0] data_out
);
    // 流水线寄存器
    reg [DW-1:0] stage_reg;
    
    // 减法运算的中间信号，将8位减法器作为示例
    wire [7:0] subtrahend;
    wire [7:0] minuend;
    wire [7:0] sub_result;
    
    // 将输入数据拆分为减数和被减数(假设数据格式)
    assign minuend = data_in[7:0];
    assign subtrahend = data_in[15:8];
    
    // 使用补码加法实现减法
    // 减法: A - B = A + (-B) = A + (~B + 1)
    wire [7:0] complement_subtrahend = ~subtrahend + 8'b1;
    assign sub_result = minuend + complement_subtrahend;
    
    // 时序逻辑
    always @(posedge clk) begin
        if (en) begin
            // 存储减法结果
            if (STAGE_ID == 1) begin
                stage_reg[7:0] <= sub_result;
                stage_reg[DW-1:8] <= data_in[DW-1:8]; // 保持其他位不变
            end else begin
                stage_reg <= data_in;
            end
        end
    end
    
    // 输出赋值
    assign data_out = stage_reg;
endmodule