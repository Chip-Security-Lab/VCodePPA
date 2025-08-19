//SystemVerilog
module bin2onecold #(parameter BIN_WIDTH = 3) (
    input wire [BIN_WIDTH-1:0] bin_in,
    output wire [(2**BIN_WIDTH)-1:0] onecold_out
);
    wire [BIN_WIDTH-1:0] bin_in_twos_complement;
    wire [(2**BIN_WIDTH)-1:0] shift_result;
    
    // Compute two's complement of bin_in for subtraction using addition
    assign bin_in_twos_complement = (~bin_in) + 1'b1;

    // Shift operation using two's complement addition
    assign shift_result = (1'b1 << (bin_in_twos_complement + (2**BIN_WIDTH))) >> (2**BIN_WIDTH);

    assign onecold_out = ~shift_result;

endmodule