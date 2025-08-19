//SystemVerilog
module mux_4to1_pipeline (
    input  wire         clk,             // Clock for pipelining
    input  wire         rst_n,           // Asynchronous active-low reset
    input  wire [1:0]   sel,             // 2-bit selection lines
    input  wire [7:0]   in0,             // Data input 0
    input  wire [7:0]   in1,             // Data input 1
    input  wire [7:0]   in2,             // Data input 2
    input  wire [7:0]   in3,             // Data input 3
    output reg  [7:0]   data_out         // Output data
);

    //----- Pipeline Stage 1: Mux Selection (Combinational) -----
    reg [7:0] mux_result_stage1;

    always @(*) begin
        case(sel)
            2'b00: mux_result_stage1 = in0;
            2'b01: mux_result_stage1 = in1;
            2'b10: mux_result_stage1 = in2;
            2'b11: mux_result_stage1 = in3;
            default: mux_result_stage1 = 8'd0;
        endcase
    end

    //----- Pipeline Stage 2: Output Register (Moved input register here) -----
    reg [7:0] mux_result_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mux_result_stage2 <= 8'd0;
        else
            mux_result_stage2 <= mux_result_stage1;
    end

    //----- Pipeline Stage 3: Output Register -----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'd0;
        else
            data_out <= mux_result_stage2;
    end

endmodule