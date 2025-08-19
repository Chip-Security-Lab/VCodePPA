//SystemVerilog
// 顶层模块
module int_ctrl_delayed #(
    parameter CYCLE = 4  // 增加流水线深度
)(
    input clk, rst,
    input [7:0] req_in,
    output [2:0] delayed_grant
);
    // 内部连线
    wire [7:0] req_stage1;
    wire [7:0] req_stage2;
    wire [7:0] req_stage3;
    wire [7:0] req_stage4;
    wire [2:0] grant_stage1;
    
    // 实例化流水线寄存器子模块
    request_pipeline #(
        .STAGES(CYCLE)
    ) req_pipeline_inst (
        .clk(clk),
        .rst(rst),
        .req_in(req_in),
        .req_stage1(req_stage1),
        .req_stage2(req_stage2),
        .req_stage3(req_stage3),
        .req_stage4(req_stage4)
    );
    
    // 实例化优先编码器子模块
    priority_encoder encoder_inst (
        .req_in(req_stage4),
        .grant_out(grant_stage1)
    );
    
    // 将优先编码器输出添加到流水线
    grant_pipeline grant_pipe_inst (
        .clk(clk),
        .rst(rst),
        .grant_in(grant_stage1),
        .grant_out(delayed_grant)
    );
endmodule

// 流水线寄存器子模块
module request_pipeline #(
    parameter STAGES = 4
)(
    input clk,
    input rst,
    input [7:0] req_in,
    output reg [7:0] req_stage1,
    output reg [7:0] req_stage2,
    output reg [7:0] req_stage3,
    output reg [7:0] req_stage4
);
    // 实现流水线寄存器
    always @(posedge clk) begin
        if(rst) begin
            req_stage1 <= 8'b0;
            req_stage2 <= 8'b0;
            req_stage3 <= 8'b0;
            req_stage4 <= 8'b0;
        end else begin
            req_stage1 <= req_in;
            req_stage2 <= req_stage1;
            req_stage3 <= req_stage2;
            req_stage4 <= req_stage3;
        end
    end
endmodule

// 优先编码器子模块 - 将逻辑分为两个阶段
module priority_encoder (
    input [7:0] req_in,
    output reg [2:0] grant_out
);
    // 对输入进行编码，分解复杂逻辑为更简单的组合逻辑
    reg [3:0] upper_priority;
    reg [3:0] lower_priority;
    
    always @(*) begin
        // 第一阶段：预处理优先级
        upper_priority[3] = req_in[7];
        upper_priority[2] = ~req_in[7] & req_in[6];
        upper_priority[1] = ~req_in[7] & ~req_in[6] & req_in[5];
        upper_priority[0] = ~req_in[7] & ~req_in[6] & ~req_in[5] & req_in[4];
        
        lower_priority[3] = req_in[3];
        lower_priority[2] = ~req_in[3] & req_in[2];
        lower_priority[1] = ~req_in[3] & ~req_in[2] & req_in[1];
        lower_priority[0] = ~req_in[3] & ~req_in[2] & ~req_in[1] & req_in[0];
        
        // 第二阶段：最终优先级编码
        if (|upper_priority) begin
            if (upper_priority[3])
                grant_out = 3'd7;
            else if (upper_priority[2])
                grant_out = 3'd6;
            else if (upper_priority[1])
                grant_out = 3'd5;
            else
                grant_out = 3'd4;
        end else begin
            if (lower_priority[3])
                grant_out = 3'd3;
            else if (lower_priority[2])
                grant_out = 3'd2;
            else if (lower_priority[1])
                grant_out = 3'd1;
            else
                grant_out = 3'd0;
        end
    end
endmodule

// 新增的grant输出流水线寄存器
module grant_pipeline (
    input clk,
    input rst,
    input [2:0] grant_in,
    output reg [2:0] grant_out
);
    // 编码器输出的流水线寄存
    always @(posedge clk) begin
        if(rst) begin
            grant_out <= 3'b0;
        end else begin
            grant_out <= grant_in;
        end
    end
endmodule