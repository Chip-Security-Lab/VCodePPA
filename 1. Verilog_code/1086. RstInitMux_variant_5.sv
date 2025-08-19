//SystemVerilog
module RstInitMux #(parameter DW=8) (
    input wire clk,
    input wire rst,
    input wire [2:0] sel,
    input wire [7:0][DW-1:0] din,
    output reg [DW-1:0] dout
);

    // Synchronous register for inputs
    reg [2:0] sel_reg;
    reg [DW-1:0] din0_reg;
    reg [7:0][DW-1:0] din_reg;

    // Register input signals on rising clock edge
    always @(posedge clk) begin
        sel_reg   <= sel;
        din0_reg  <= din[0];
        din_reg   <= din;
    end

    // Combinational logic for mux output
    wire [DW-1:0] mux_comb_out;
    assign mux_comb_out = rst ? din0_reg : din_reg[sel_reg];

    // Sequential logic for output register
    always @(posedge clk) begin
        dout <= mux_comb_out;
    end

endmodule