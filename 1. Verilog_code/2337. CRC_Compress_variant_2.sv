//SystemVerilog - IEEE 1364-2005
// 顶层模块 - 流水线优化版本
module CRC_Compress #(
    parameter POLY = 32'h04C11DB7
)(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    output wire ready_out,
    input wire [31:0] data_in,
    output wire valid_out,
    input wire ready_in,
    output wire [31:0] crc_out
);
    // 流水线阶段寄存器
    reg [31:0] data_stage1, data_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 内部连线
    wire crc_feedback_stage1;
    wire [31:0] polynomial_value_stage1;
    wire [31:0] next_crc_stage2;
    wire [31:0] crc_stage3;
    
    // 流水线控制信号
    wire stall;
    wire stage1_ready, stage2_ready, stage3_ready;
    
    // 背压控制逻辑
    assign stall = valid_stage3 && !ready_in;
    assign stage3_ready = !stall;
    assign stage2_ready = !valid_stage3 || ready_in;
    assign stage1_ready = !valid_stage2 || stage2_ready;
    assign ready_out = !valid_stage1 || stage1_ready;
    
    // 第一阶段 - 反馈检测和多项式选择
    CRC_Feedback_Detector u_feedback_detector (
        .crc_msb(crc_out[31]),
        .data_msb(data_in[31]),
        .crc_feedback(crc_feedback_stage1)
    );
    
    CRC_Polynomial_Selector #(
        .POLY(POLY)
    ) u_polynomial_selector (
        .crc_feedback(crc_feedback_stage1),
        .polynomial_value(polynomial_value_stage1)
    );
    
    // 第一阶段流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 32'h0;
            valid_stage1 <= 1'b0;
            polynomial_value_stage2 <= 32'h0;
        end else if (stage1_ready) begin
            if (valid_in && ready_out) begin
                data_stage1 <= data_in;
                valid_stage1 <= 1'b1;
                polynomial_value_stage2 <= polynomial_value_stage1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二阶段 - CRC下一个值计算
    reg [31:0] polynomial_value_stage2;
    reg [31:0] crc_current_stage2;
    
    CRC_Next_Value_Calculator u_next_value_calculator (
        .crc_current(crc_current_stage2),
        .polynomial_value(polynomial_value_stage2),
        .crc_next(next_crc_stage2)
    );
    
    // 第二阶段流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 32'h0;
            valid_stage2 <= 1'b0;
            crc_current_stage2 <= 32'h0;
        end else if (stage2_ready) begin
            if (valid_stage1) begin
                data_stage2 <= data_stage1;
                valid_stage2 <= valid_stage1;
                crc_current_stage2 <= crc_out;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 第三阶段 - CRC寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
        end else if (stage3_ready) begin
            if (valid_stage2) begin
                valid_stage3 <= valid_stage2;
            end else if (ready_in) begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
    // CRC寄存器
    CRC_Register u_crc_register (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_stage2 && stage2_ready),
        .crc_next(next_crc_stage2),
        .crc(crc_out)
    );
    
    // 输出赋值
    assign valid_out = valid_stage3;
    
endmodule

// 子模块：反馈检测器
module CRC_Feedback_Detector (
    input wire crc_msb,
    input wire data_msb,
    output wire crc_feedback
);
    assign crc_feedback = crc_msb ^ data_msb;
endmodule

// 子模块：多项式选择器
module CRC_Polynomial_Selector #(
    parameter POLY = 32'h04C11DB7
)(
    input wire crc_feedback,
    output wire [31:0] polynomial_value
);
    assign polynomial_value = crc_feedback ? POLY : 32'h0;
endmodule

// 子模块：CRC下一个值计算
module CRC_Next_Value_Calculator (
    input wire [31:0] crc_current,
    input wire [31:0] polynomial_value,
    output wire [31:0] crc_next
);
    assign crc_next = {crc_current[23:0], 1'b0} ^ polynomial_value;
endmodule

// 子模块：CRC寄存器
module CRC_Register (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [31:0] crc_next,
    output reg [31:0] crc
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc <= 32'h0;
        end else if (en) begin
            crc <= crc_next;
        end
    end
endmodule