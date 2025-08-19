//SystemVerilog
// Top-level module
module Conditional_AND (
    input wire clk,       // 时钟输入
    input wire rst_n,     // 低电平有效复位
    input wire sel,       // 选择信号
    input wire [7:0] op_a, // 操作数A
    input wire [7:0] op_b, // 操作数B
    output wire [7:0] res  // 结果输出
);
    // Internal connections
    wire sel_r1;
    wire [7:0] op_a_r1, op_b_r1;
    wire [7:0] and_result;
    wire [7:0] mux_result;

    // Stage 1: Input pipeline register
    InputStage u_input_stage (
        .clk(clk),
        .rst_n(rst_n),
        .sel_in(sel),
        .op_a_in(op_a),
        .op_b_in(op_b),
        .sel_out(sel_r1),
        .op_a_out(op_a_r1),
        .op_b_out(op_b_r1)
    );

    // Stage 2: Computation pipeline
    ComputeStage u_compute_stage (
        .clk(clk),
        .rst_n(rst_n),
        .sel_in(sel_r1),
        .op_a_in(op_a_r1),
        .op_b_in(op_b_r1),
        .and_result(and_result),
        .mux_out(mux_result)
    );

    // Stage 3: Output pipeline register
    OutputStage u_output_stage (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(mux_result),
        .data_out(res)
    );

endmodule

// Input stage module - Responsible for registering input signals
module InputStage (
    input wire clk,
    input wire rst_n,
    input wire sel_in,
    input wire [7:0] op_a_in,
    input wire [7:0] op_b_in,
    output reg sel_out,
    output reg [7:0] op_a_out,
    output reg [7:0] op_b_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_out <= 1'b0;
            op_a_out <= 8'h0;
            op_b_out <= 8'h0;
        end else begin
            sel_out <= sel_in;
            op_a_out <= op_a_in;
            op_b_out <= op_b_in;
        end
    end

endmodule

// Compute stage module - Performs the AND operation and multiplexing
module ComputeStage (
    input wire clk,
    input wire rst_n,
    input wire sel_in,
    input wire [7:0] op_a_in,
    input wire [7:0] op_b_in,
    output reg [7:0] and_result,
    output reg [7:0] mux_out
);

    // Registered AND operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 8'h0;
        end else begin
            and_result <= op_a_in & op_b_in;
        end
    end
    
    // Multiplexer stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_out <= 8'h0;
        end else begin
            mux_out <= sel_in ? and_result : 8'hFF;
        end
    end

endmodule

// Output stage module - Registers the final result
module OutputStage (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h0;
        end else begin
            data_out <= data_in;
        end
    end

endmodule