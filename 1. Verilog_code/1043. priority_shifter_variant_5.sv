//SystemVerilog
module priority_shifter (
    input  [15:0] in_data,
    input  [15:0] priority_mask,
    output [15:0] out_data
);
    // --- Pipeline Stage 1: Priority Encoding ---
    wire [3:0] pipeline_priority_stage;
    priority_encoder_16 u_priority_encoder (
        .mask_in(priority_mask),
        .priority_out(pipeline_priority_stage)
    );

    // --- Pipeline Register Between Stages ---
    reg [3:0] priority_reg;
    always @(*) begin
        priority_reg = pipeline_priority_stage;
    end

    // --- Pipeline Stage 2: Data Shift with Signed Multiplier Optimization ---
    wire [15:0] pipeline_shift_stage;
    data_shifter_mul_opt_16 u_data_shifter (
        .data_in(in_data),
        .shift_amt(priority_reg),
        .data_out(pipeline_shift_stage)
    );

    // --- Optional Pipeline Register Before Output ---
    reg [15:0] out_data_reg;
    always @(*) begin
        out_data_reg = pipeline_shift_stage;
    end

    assign out_data = out_data_reg;

endmodule

// --- Priority Encoder Module ---
// Encodes the highest set bit in mask_in[15:0] to a 4-bit priority_out
module priority_encoder_16 (
    input  [15:0] mask_in,
    output reg [3:0] priority_out
);
    always @(*) begin : PRIORITY_ENCODING
        casez (mask_in)
            16'b1???????????????: priority_out = 4'd15;
            16'b01??????????????: priority_out = 4'd14;
            16'b001?????????????: priority_out = 4'd13;
            16'b0001????????????: priority_out = 4'd12;
            16'b00001???????????: priority_out = 4'd11;
            16'b000001??????????: priority_out = 4'd10;
            16'b0000001?????????: priority_out = 4'd9;
            16'b00000001????????: priority_out = 4'd8;
            16'b000000001???????: priority_out = 4'd7;
            16'b0000000001??????: priority_out = 4'd6;
            16'b00000000001?????: priority_out = 4'd5;
            16'b000000000001????: priority_out = 4'd4;
            16'b0000000000001???: priority_out = 4'd3;
            16'b00000000000001??: priority_out = 4'd2;
            16'b000000000000001?: priority_out = 4'd1;
            16'b0000000000000001: priority_out = 4'd0;
            default            : priority_out = 4'd0;
        endcase
    end
endmodule

// --- Data Shifter Module with Signed Multiplier Optimization ---
// Shifts data_in left by shift_amt[3:0], outputs data_out[15:0] using signed multiplication
module data_shifter_mul_opt_16 (
    input  [15:0] data_in,
    input  [3:0]  shift_amt,
    output reg [15:0] data_out
);
    // Internal signals for signed arithmetic
    reg signed [15:0] signed_data_in;
    reg signed [31:0] signed_mult_result;
    reg [15:0] shift_left_value;

    always @(*) begin : SHIFT_LEFT_MULT_OPT
        // Calculate 2^shift_amt as a one-hot left shift: 1 << shift_amt
        shift_left_value = 16'h0001 << shift_amt;
        signed_data_in = data_in;
        signed_mult_result = signed_data_in * $signed({{16{1'b0}}, shift_left_value});
        data_out = signed_mult_result[15:0];
    end
endmodule