//SystemVerilog
// Top-level module: mux_sync_reset_pipeline
// Function: 2-stage pipelined 8-bit multiplexer with synchronous reset and output register

module mux_sync_reset_pipeline (
    input  wire        clk,                   // Clock input
    input  wire        rst,                   // Synchronous reset
    input  wire [7:0]  input_0,               // Data input 0
    input  wire [7:0]  input_1,               // Data input 1
    input  wire        sel_line,              // Selection input
    input  wire        valid_in,              // Valid input for pipeline
    output wire [7:0]  mux_result,            // Registered output
    output wire        valid_out              // Valid output for pipeline
);

    // Stage 1: Register inputs and valid
    reg [7:0] input_0_stage1;
    reg [7:0] input_1_stage1;
    reg       sel_line_stage1;
    reg       valid_stage1;

    always @(posedge clk) begin
        if (rst) begin
            input_0_stage1 <= 8'b0;
            input_1_stage1 <= 8'b0;
            sel_line_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            input_0_stage1 <= input_0;
            input_1_stage1 <= input_1;
            sel_line_stage1 <= sel_line;
            valid_stage1 <= valid_in;
        end
    end

    // Stage 2: Multiplexing and output register
    reg [7:0] mux_result_stage2;
    reg       valid_stage2;

    always @(posedge clk) begin
        if (rst) begin
            mux_result_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            mux_result_stage2 <= sel_line_stage1 ? input_1_stage1 : input_0_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    assign mux_result = mux_result_stage2;
    assign valid_out = valid_stage2;

endmodule