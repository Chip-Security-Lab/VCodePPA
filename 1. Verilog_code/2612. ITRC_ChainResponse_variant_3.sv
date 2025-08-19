//SystemVerilog
// Masking module
module ITRC_Masking #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] int_src,
    input [WIDTH-1:0] current_int,
    output [WIDTH-1:0] masked_src,
    output [WIDTH-1:0] masked_src_inv
);
    assign masked_src = int_src & ~current_int;
    assign masked_src_inv = ~masked_src;
endmodule

// Inversion subtractor module
module ITRC_InversionSubtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] masked_src_inv,
    output [WIDTH-1:0] sub_result
);
    assign sub_result = masked_src_inv + 1;
endmodule

// Control logic module
module ITRC_ControlLogic #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input ack,
    input [WIDTH-1:0] masked_src,
    input [WIDTH-1:0] sub_result,
    input [WIDTH-1:0] current_int,
    output reg [WIDTH-1:0] next_int
);
    always @(posedge clk) begin
        if (!rst_n) 
            next_int <= 0;
        else if (ack)
            next_int <= {1'b0, current_int[WIDTH-1:1]};
        else if (!current_int[0])
            next_int <= masked_src ^ sub_result;
    end
endmodule

// Top-level module
module ITRC_ChainResponse #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    input ack,
    output [WIDTH-1:0] current_int
);
    wire [WIDTH-1:0] masked_src;
    wire [WIDTH-1:0] masked_src_inv;
    wire [WIDTH-1:0] sub_result;
    wire [WIDTH-1:0] next_int;
    
    // Instantiate masking module
    ITRC_Masking #(.WIDTH(WIDTH)) masking_inst (
        .int_src(int_src),
        .current_int(current_int),
        .masked_src(masked_src),
        .masked_src_inv(masked_src_inv)
    );
    
    // Instantiate inversion subtractor module
    ITRC_InversionSubtractor #(.WIDTH(WIDTH)) inv_sub_inst (
        .masked_src_inv(masked_src_inv),
        .sub_result(sub_result)
    );
    
    // Instantiate control logic module
    ITRC_ControlLogic #(.WIDTH(WIDTH)) control_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ack(ack),
        .masked_src(masked_src),
        .sub_result(sub_result),
        .current_int(current_int),
        .next_int(next_int)
    );
    
    // Register for current_int
    reg [WIDTH-1:0] current_int_reg;
    always @(posedge clk) begin
        if (!rst_n)
            current_int_reg <= 0;
        else
            current_int_reg <= next_int;
    end
    
    assign current_int = current_int_reg;
endmodule