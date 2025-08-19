// 顶层模块
module subtractor_fsm (
    input wire clk,       // 时钟信号
    input wire reset,     // 复位信号
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output wire [7:0] res // 差
);

    // 流水线控制信号
    wire valid_stage1, valid_stage2, valid_stage3;
    wire ready_stage1, ready_stage2, ready_stage3;
    
    // 流水线数据信号
    wire [7:0] a_stage1, b_stage1;
    wire [7:0] b_inverted_stage2;
    wire [7:0] b_complement_stage2;
    wire [7:0] sum_result_stage3;
    wire carry_out_stage3;
    wire [7:0] final_result_stage3;
    
    // 实例化流水线控制器
    pipeline_controller pipe_ctrl (
        .clk(clk),
        .reset(reset),
        .valid_stage1(valid_stage1),
        .valid_stage2(valid_stage2),
        .valid_stage3(valid_stage3),
        .ready_stage1(ready_stage1),
        .ready_stage2(ready_stage2),
        .ready_stage3(ready_stage3)
    );
    
    // 第一级流水线：输入寄存器
    stage1_registers stage1 (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_stage1),
        .ready_out(ready_stage1),
        .a_in(a),
        .b_in(b),
        .a_out(a_stage1),
        .b_out(b_stage1)
    );
    
    // 第二级流水线：补码计算
    stage2_complement stage2 (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_stage2),
        .ready_out(ready_stage2),
        .a_in(a_stage1),
        .b_in(b_stage1),
        .b_inverted_out(b_inverted_stage2),
        .b_complement_out(b_complement_stage2)
    );
    
    // 第三级流水线：加法和结果处理
    stage3_adder stage3 (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_stage3),
        .ready_out(ready_stage3),
        .a_in(a_stage1),
        .b_complement_in(b_complement_stage2),
        .sum_out(sum_result_stage3),
        .carry_out(carry_out_stage3),
        .final_result_out(final_result_stage3)
    );
    
    // 输出寄存器
    output_register out_reg (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_stage3),
        .data_in(final_result_stage3),
        .data_out(res)
    );

endmodule

// 流水线控制器
module pipeline_controller (
    input wire clk,
    input wire reset,
    output reg valid_stage1,
    output reg valid_stage2,
    output reg valid_stage3,
    input wire ready_stage1,
    input wire ready_stage2,
    input wire ready_stage3
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            valid_stage2 <= valid_stage1 & ready_stage1;
            valid_stage3 <= valid_stage2 & ready_stage2;
        end
    end

endmodule

// 第一级流水线寄存器
module stage1_registers (
    input wire clk,
    input wire reset,
    input wire valid_in,
    output reg ready_out,
    input wire [7:0] a_in,
    input wire [7:0] b_in,
    output reg [7:0] a_out,
    output reg [7:0] b_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_out <= 8'b0;
            b_out <= 8'b0;
            ready_out <= 1'b0;
        end else if (valid_in) begin
            a_out <= a_in;
            b_out <= b_in;
            ready_out <= 1'b1;
        end else begin
            ready_out <= 1'b0;
        end
    end

endmodule

// 第二级流水线：补码计算
module stage2_complement (
    input wire clk,
    input wire reset,
    input wire valid_in,
    output reg ready_out,
    input wire [7:0] a_in,
    input wire [7:0] b_in,
    output reg [7:0] b_inverted_out,
    output reg [7:0] b_complement_out
);

    wire [7:0] b_inverted;
    wire [7:0] b_plus_1;
    
    assign b_inverted = ~b_in;
    assign b_plus_1 = b_inverted + 1;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            b_inverted_out <= 8'b0;
            b_complement_out <= 8'b0;
            ready_out <= 1'b0;
        end else if (valid_in) begin
            b_inverted_out <= b_inverted;
            b_complement_out <= b_plus_1;
            ready_out <= 1'b1;
        end else begin
            ready_out <= 1'b0;
        end
    end

endmodule

// 第三级流水线：加法和结果处理
module stage3_adder (
    input wire clk,
    input wire reset,
    input wire valid_in,
    output reg ready_out,
    input wire [7:0] a_in,
    input wire [7:0] b_complement_in,
    output reg [7:0] sum_out,
    output reg carry_out,
    output reg [7:0] final_result_out
);

    wire [8:0] sum_with_carry;
    
    assign sum_with_carry = a_in + b_complement_in;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sum_out <= 8'b0;
            carry_out <= 1'b0;
            final_result_out <= 8'b0;
            ready_out <= 1'b0;
        end else if (valid_in) begin
            sum_out <= sum_with_carry[7:0];
            carry_out <= sum_with_carry[8];
            final_result_out <= sum_with_carry[8] ? sum_with_carry[7:0] : ~sum_with_carry[7:0] + 1;
            ready_out <= 1'b1;
        end else begin
            ready_out <= 1'b0;
        end
    end

endmodule

// 输出寄存器
module output_register (
    input wire clk,
    input wire reset,
    input wire valid_in,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= 8'b0;
        end else if (valid_in) begin
            data_out <= data_in;
        end
    end

endmodule