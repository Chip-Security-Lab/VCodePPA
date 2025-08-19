//SystemVerilog
// Top-level module
module shadow_reg #(parameter DW=16) (
    input clk, en, commit,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
    // Internal connections
    wire [DW-1:0] working_data;
    
    // Working register submodule
    working_register #(
        .DATA_WIDTH(DW)
    ) u_working_register (
        .clk(clk),
        .en(en),
        .data_in(din),
        .data_out(working_data)
    );
    
    // Shadow register submodule
    shadow_register #(
        .DATA_WIDTH(DW)
    ) u_shadow_register (
        .clk(clk),
        .commit(commit),
        .data_in(working_data),
        .data_out(dout)
    );
endmodule

// Working register submodule
module working_register #(
    parameter DATA_WIDTH = 16
)(
    input clk,
    input en,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        if(en) data_out <= data_in;
    end
endmodule

// Shadow register submodule with combined always block
module shadow_register #(
    parameter DATA_WIDTH = 16
)(
    input clk,
    input commit,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        if(commit) data_out <= data_in;
    end
endmodule