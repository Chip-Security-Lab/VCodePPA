module combo_shifter(
    input [15:0] data,
    input [3:0] shift_val,
    input [1:0] op_mode,    // 00:LSL, 01:LSR, 10:ASR, 11:ROR
    output reg [15:0] result
);
    always @(*) begin
        case (op_mode)
            2'b00: result = data << shift_val;
            2'b01: result = data >> shift_val;
            2'b10: result = $signed(data) >>> shift_val;
            2'b11: result = (data >> shift_val) | (data << (16-shift_val));
        endcase
    end
endmodule