module sync_arithmetic_right_shifter #(
    parameter DW = 32,  // Data width
    parameter SW = 5    // Shift width
)(
    input                  clk_i,
    input                  en_i,
    input      [DW-1:0]    data_i,
    input      [SW-1:0]    shift_i,
    output reg [DW-1:0]    data_o
);
    // Sign extension for arithmetic right shift
    always @(posedge clk_i) begin
        if (en_i) begin
            // >>> operator performs arithmetic right shift (sign extended)
            data_o <= $signed(data_i) >>> shift_i;
        end
    end
endmodule