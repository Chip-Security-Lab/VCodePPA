module barrel_shifter (
    input wire [7:0] data_in,     // Input data
    input wire [2:0] shift_amt,   // Shift amount
    input wire direction,         // 0: right, 1: left
    output reg [7:0] shifted_out  // Shifted result
);
    always @(*) begin
        shifted_out = direction ? (data_in << shift_amt) : (data_in >> shift_amt);
    end
endmodule