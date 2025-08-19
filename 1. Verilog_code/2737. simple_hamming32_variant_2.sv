//SystemVerilog
module parity_calculator(
    input [31:0] data_in,
    output [5:0] parity_out
);
    assign parity_out[0] = ^(data_in & 32'h55555555);
    assign parity_out[1] = ^(data_in & 32'h66666666);
    assign parity_out[2] = ^(data_in & 32'h78787878);
    assign parity_out[3] = ^(data_in & 32'h7F807F80);
    assign parity_out[4] = ^(data_in & 32'h7FFF8000);
    assign parity_out[5] = ^(data_in & 32'h7FFFFFFF);
endmodule

module data_assembler(
    input [31:0] data_in,
    input [5:0] parity_in,
    output [38:0] data_out
);
    assign data_out = {data_in, parity_in, 1'b0};
endmodule

module simple_hamming32(
    input [31:0] data_in,
    output [38:0] data_out
);
    wire [5:0] parity;
    
    parity_calculator parity_calc_inst(
        .data_in(data_in),
        .parity_out(parity)
    );
    
    data_assembler data_asm_inst(
        .data_in(data_in),
        .parity_in(parity),
        .data_out(data_out)
    );
endmodule