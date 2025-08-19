//SystemVerilog
module tristate_mux (
    input  wire        clk,              // System clock for pipelined data flow
    input  wire [7:0]  source_a,         // Data source A
    input  wire [7:0]  source_b,         // Data source B
    input  wire        select,           // Multiplexer select control
    input  wire        output_enable,    // Tristate output enable
    output wire [7:0]  data_bus          // Tristate output bus
);

    // Pipeline Stage 1: Combined Input Latching and Multiplexing
    reg [7:0] muxed_data_stage1;
    reg       output_enable_stage1;

    always @(posedge clk) begin
        muxed_data_stage1    <= (select) ? source_b : source_a;
        output_enable_stage1 <= output_enable;
    end

    // Pipeline Stage 2: Output Register
    reg [7:0] data_stage2;
    reg       output_enable_stage2;

    always @(posedge clk) begin
        data_stage2          <= muxed_data_stage1;
        output_enable_stage2 <= output_enable_stage1;
    end

    // Tristate Output Assignment
    assign data_bus = output_enable_stage2 ? data_stage2 : 8'bz;

endmodule