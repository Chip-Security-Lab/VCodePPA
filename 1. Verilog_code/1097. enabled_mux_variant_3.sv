//SystemVerilog
// Top-level module: enabled_mux_optimized
// Function: Applies forward register retiming to optimize timing by moving registers after the multiplexer

module enabled_mux (
    input wire clock,               // System clock
    input wire enable,              // Enable signal
    input wire [1:0] select,        // Input selector
    input wire [7:0] in_a, in_b, in_c, in_d, // Data inputs
    output wire [7:0] data_out      // Registered output
);

    // Registered inputs after the multiplexer (retimed)
    wire [7:0] mux_data_out;

    // Multiplexer submodule instantiation
    mux_select #(
        .DATA_WIDTH(8)
    ) mux_select_inst (
        .sel(select),
        .in0(in_a),
        .in1(in_b),
        .in2(in_c),
        .in3(in_d),
        .mux_out(mux_data_out)
    );

    // Register with enable, placed after the MUX (retimed)
    reg_en #(
        .DATA_WIDTH(8)
    ) reg_en_inst (
        .clk(clock),
        .en(enable),
        .d(mux_data_out),
        .q(data_out)
    );

endmodule

// Submodule: mux_select
// Function: 4-to-1 multiplexer for parameterizable data width
module mux_select #(
    parameter DATA_WIDTH = 8
)(
    input wire [1:0] sel,                   // Selector
    input wire [DATA_WIDTH-1:0] in0,        // Input 0
    input wire [DATA_WIDTH-1:0] in1,        // Input 1
    input wire [DATA_WIDTH-1:0] in2,        // Input 2
    input wire [DATA_WIDTH-1:0] in3,        // Input 3
    output wire [DATA_WIDTH-1:0] mux_out    // Multiplexer output
);
    // Combinational 4-to-1 multiplexer logic
    assign mux_out = (sel == 2'b00) ? in0 :
                     (sel == 2'b01) ? in1 :
                     (sel == 2'b10) ? in2 :
                     in3;
endmodule

// Submodule: reg_en
// Function: Register with clock enable for parameterizable data width
module reg_en #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,                         // System clock
    input wire en,                          // Clock enable
    input wire [DATA_WIDTH-1:0] d,          // Data input
    output reg [DATA_WIDTH-1:0] q           // Registered output
);
    // Sequential logic with enable
    always @(posedge clk) begin
        if (en) begin
            q <= d;
        end
    end
endmodule