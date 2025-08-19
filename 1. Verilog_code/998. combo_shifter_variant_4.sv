//SystemVerilog
module combo_shifter(
    input  [15:0] data,
    input  [3:0]  shift_val,
    input  [1:0]  op_mode,    // 00:LSL, 01:LSR, 10:ASR, 11:ROR
    output reg [15:0] result
);

    wire [15:0] lsl_result;
    wire [15:0] lsr_result;
    wire [15:0] asr_result;
    wire [15:0] ror_result;

    // Optimized LSL: Use shift operator, no multiplier
    assign lsl_result = (shift_val == 4'd0) ? data : ((shift_val < 4'd16) ? (data << shift_val) : 16'b0);

    // Optimized LSR: Use shift operator, no multiplier
    assign lsr_result = (shift_val == 4'd0) ? data : ((shift_val < 4'd16) ? (data >> shift_val) : 16'b0);

    // Optimized ASR: Use signed shift for arithmetic shift right
    assign asr_result = (shift_val == 4'd0) ? data : ((shift_val < 4'd16) ? $signed(data) >>> shift_val : {16{data[15]}});

    // Optimized ROR: Use concatenation for rotate right
    assign ror_result = (shift_val == 4'd0) ? data :
                        ((shift_val < 4'd16) ? ((data >> shift_val) | (data << (16 - shift_val))) :
                        data);

    always @(*) begin
        case (op_mode)
            2'b00: result = lsl_result;
            2'b01: result = lsr_result;
            2'b10: result = asr_result;
            2'b11: result = ror_result;
            default: result = 16'b0;
        endcase
    end

endmodule