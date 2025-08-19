module barrel_shifter (
    input wire [7:0] data_in,
    input wire [2:0] shift_amount,
    input wire direction, // 0: right, 1: left
    output reg [7:0] data_out
);
    always @(*) begin
        if (direction)
            data_out = data_in << shift_amount;
        else
            data_out = data_in >> shift_amount;
    end
endmodule