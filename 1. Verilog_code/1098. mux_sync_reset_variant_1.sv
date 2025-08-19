//SystemVerilog
module mux_sync_reset_pipeline (
    input wire clk,                       // Clock input
    input wire rst,                       // Synchronous reset
    input wire [7:0] input_0, input_1,    // Data inputs
    input wire sel_line,                  // Selection input
    input wire start,                     // Pipeline start signal
    output reg [7:0] mux_result,          // Registered output
    output reg valid_out                  // Output valid signal
);

    // Stage 1 registers
    reg [7:0] input_0_stage1, input_1_stage1;
    reg sel_line_stage1;
    reg valid_stage1;

    // Stage 2 registers (output stage)
    reg [7:0] mux_result_stage2;
    reg valid_stage2;

    // Stage 1: Register inputs and selection
    always @(posedge clk) begin
        if (rst) begin
            input_0_stage1  <= 8'b0;
            input_1_stage1  <= 8'b0;
            sel_line_stage1 <= 1'b0;
            valid_stage1    <= 1'b0;
        end else begin
            input_0_stage1  <= input_0;
            input_1_stage1  <= input_1;
            sel_line_stage1 <= sel_line;
            valid_stage1    <= start;
        end
    end

    // Stage 2: Multiplexing
    always @(posedge clk) begin
        if (rst) begin
            mux_result_stage2 <= 8'b0;
            valid_stage2      <= 1'b0;
        end else begin
            mux_result_stage2 <= sel_line_stage1 ? input_1_stage1 : input_0_stage1;
            valid_stage2      <= valid_stage1;
        end
    end

    // Output register
    always @(posedge clk) begin
        if (rst) begin
            mux_result <= 8'b0;
            valid_out  <= 1'b0;
        end else begin
            mux_result <= mux_result_stage2;
            valid_out  <= valid_stage2;
        end
    end

endmodule