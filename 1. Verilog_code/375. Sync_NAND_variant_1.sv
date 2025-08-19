//SystemVerilog
//IEEE 1364-2005 Verilog
// Top-level module
module Sync_NAND #(
    parameter DATA_WIDTH = 8
)(
    input  wire                 clk,
    input  wire [DATA_WIDTH-1:0] d1, d2,
    output wire [DATA_WIDTH-1:0] q
);
    wire [DATA_WIDTH-1:0] nand_result;
    
    // Instantiate the combinational logic module
    NAND_Logic #(
        .WIDTH(DATA_WIDTH)
    ) u_nand_logic (
        .in1(d1),
        .in2(d2),
        .out(nand_result)
    );
    
    // Instantiate the register module
    Output_Register #(
        .WIDTH(DATA_WIDTH)
    ) u_output_register (
        .clk(clk),
        .data_in(nand_result),
        .data_out(q)
    );
    
endmodule

// Combinational logic module for NAND operation
module NAND_Logic #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] in1, in2,
    output wire [WIDTH-1:0] out
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_nand
            assign out[i] = ~(in1[i] & in2[i]);
        end
    endgenerate
endmodule

// Register module for synchronous output with reset capability
module Output_Register #(
    parameter WIDTH = 8
)(
    input  wire              clk,
    input  wire [WIDTH-1:0]  data_in,
    output reg  [WIDTH-1:0]  data_out
);
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule