//SystemVerilog
// 顶层模块
module ext_ack_ismu(
    input wire i_clk, i_rst,
    input wire [3:0] i_int,
    input wire [3:0] i_mask,
    input wire i_ext_ack,
    input wire [1:0] i_ack_id,
    output wire o_int_req,
    output wire [1:0] o_int_id
);
    // 内部信号连接
    wire [3:0] masked_int_stage1;
    wire [3:0] pending_stage1, pending_stage2, pending_stage3;
    wire i_ext_ack_stage1, i_ext_ack_stage2;
    wire [1:0] i_ack_id_stage1, i_ack_id_stage2;
    wire has_pending_stage1, has_pending_stage2;
    wire [1:0] priority_id_stage1;

    // 实例化输入处理模块
    input_stage input_proc (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_int(i_int),
        .i_mask(i_mask),
        .i_ext_ack(i_ext_ack),
        .i_ack_id(i_ack_id),
        .o_masked_int(masked_int_stage1),
        .o_ext_ack(i_ext_ack_stage1),
        .o_ack_id(i_ack_id_stage1)
    );

    // 实例化中断挂起状态处理模块
    pending_stage pending_proc (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_masked_int(masked_int_stage1),
        .i_ext_ack(i_ext_ack_stage1),
        .i_ack_id(i_ack_id_stage1),
        .o_pending(pending_stage1),
        .o_ext_ack(i_ext_ack_stage2),
        .o_ack_id(i_ack_id_stage2)
    );

    // 实例化挂起状态预处理模块
    pending_prep pending_prepare (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_pending(pending_stage1),
        .o_pending(pending_stage2),
        .o_has_pending(has_pending_stage1)
    );

    // 实例化优先级编码器第一阶段
    priority_encode_stage1 pri_encode1 (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_pending(pending_stage2),
        .i_has_pending(has_pending_stage1),
        .o_pending(pending_stage3),
        .o_has_pending(has_pending_stage2),
        .o_priority_id(priority_id_stage1)
    );

    // 实例化输出阶段模块
    output_stage output_proc (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_has_pending(has_pending_stage2),
        .i_priority_id(priority_id_stage1),
        .o_int_req(o_int_req),
        .o_int_id(o_int_id)
    );
endmodule

// 输入处理模块
module input_stage (
    input wire i_clk, i_rst,
    input wire [3:0] i_int,
    input wire [3:0] i_mask,
    input wire i_ext_ack,
    input wire [1:0] i_ack_id,
    output reg [3:0] o_masked_int,
    output reg o_ext_ack,
    output reg [1:0] o_ack_id
);
    // 第一级流水线 - 计算masked_int并注册
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_masked_int <= 4'h0;
            o_ext_ack <= 1'b0;
            o_ack_id <= 2'b00;
        end else begin
            o_masked_int <= i_int & ~i_mask;
            o_ext_ack <= i_ext_ack;
            o_ack_id <= i_ack_id;
        end
    end
endmodule

// 中断挂起状态处理模块
module pending_stage (
    input wire i_clk, i_rst,
    input wire [3:0] i_masked_int,
    input wire i_ext_ack,
    input wire [1:0] i_ack_id,
    output reg [3:0] o_pending,
    output reg o_ext_ack,
    output reg [1:0] o_ack_id
);
    // 第二级流水线 - 更新pending状态
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_pending <= 4'h0;
            o_ext_ack <= 1'b0;
            o_ack_id <= 2'b00;
        end else begin
            o_pending <= o_pending | i_masked_int;
            
            if (i_ext_ack)
                o_pending[i_ack_id] <= 1'b0;
                
            o_ext_ack <= i_ext_ack;
            o_ack_id <= i_ack_id;
        end
    end
endmodule

// 挂起状态预处理模块
module pending_prep (
    input wire i_clk, i_rst,
    input wire [3:0] i_pending,
    output reg [3:0] o_pending,
    output reg o_has_pending
);
    // 第三级流水线 - 准备优先级编码器的输入
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_pending <= 4'h0;
            o_has_pending <= 1'b0;
        end else begin
            o_pending <= i_pending;
            o_has_pending <= |i_pending;
        end
    end
endmodule

// 优先级编码器第一阶段
module priority_encode_stage1 (
    input wire i_clk, i_rst,
    input wire [3:0] i_pending,
    input wire i_has_pending,
    output reg [3:0] o_pending,
    output reg o_has_pending,
    output reg [1:0] o_priority_id
);
    // 第四级流水线 - 第一阶段优先级编码
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_pending <= 4'h0;
            o_has_pending <= 1'b0;
            o_priority_id <= 2'b00;
        end else begin
            o_pending <= i_pending;
            o_has_pending <= i_has_pending;
            
            // 优先级编码逻辑
            if (i_pending[0] || i_pending[1]) begin
                o_priority_id <= i_pending[0] ? 2'd0 : 2'd1;
            end else begin
                o_priority_id <= i_pending[2] ? 2'd2 : 2'd3;
            end
        end
    end
endmodule

// 输出阶段模块
module output_stage (
    input wire i_clk, i_rst,
    input wire i_has_pending,
    input wire [1:0] i_priority_id,
    output reg o_int_req,
    output reg [1:0] o_int_id
);
    // 第五级流水线 - 完成优先级编码并输出
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_int_req <= 1'b0;
            o_int_id <= 2'h0;
        end else begin
            o_int_req <= i_has_pending;
            o_int_id <= i_priority_id;
        end
    end
endmodule