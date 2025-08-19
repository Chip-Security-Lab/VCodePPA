//SystemVerilog
module sync_2to1_mux (
    input wire clk,                       // Clock signal
    input wire [7:0] data_a,              // Data input A
    input wire [7:0] data_b,              // Data input B
    input wire sel,                       // Selection bit
    output reg [7:0] q_out                // Registered output
);

    // Stage 1: Input latching for both data and select signals
    reg [7:0] data_a_stage1;
    reg [7:0] data_b_stage1;
    reg       sel_stage1;

    // Stage 2: Mux output registered
    reg [7:0] mux_result_stage2;

    // Pipeline Stage 1: Capture inputs and select signal
    always @(posedge clk) begin
        data_a_stage1 <= data_a;
        data_b_stage1 <= data_b;
        sel_stage1    <= sel;
    end

    // Pipeline Stage 2: Mux operation
    always @(posedge clk) begin
        mux_result_stage2 <= (sel_stage1) ? data_b_stage1 : data_a_stage1;
    end

    // Pipeline Stage 3: Output register
    always @(posedge clk) begin
        q_out <= mux_result_stage2;
    end

endmodule