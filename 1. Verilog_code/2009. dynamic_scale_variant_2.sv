//SystemVerilog
module dynamic_scale #(parameter W = 24)(
    input  wire [W-1:0] in,
    input  wire [4:0] shift,
    output wire [W-1:0] out
);

    wire shift_direction;
    wire [4:0] shift_amount;
    wire [4:0] shift_amount_lut;

    // LUT for 5-bit two's complement negation (i.e., -shift)
    reg [4:0] neg_shift_lut [0:31];
    initial begin
        neg_shift_lut[ 0] = 5'd 0;
        neg_shift_lut[ 1] = 5'd31;
        neg_shift_lut[ 2] = 5'd30;
        neg_shift_lut[ 3] = 5'd29;
        neg_shift_lut[ 4] = 5'd28;
        neg_shift_lut[ 5] = 5'd27;
        neg_shift_lut[ 6] = 5'd26;
        neg_shift_lut[ 7] = 5'd25;
        neg_shift_lut[ 8] = 5'd24;
        neg_shift_lut[ 9] = 5'd23;
        neg_shift_lut[10] = 5'd22;
        neg_shift_lut[11] = 5'd21;
        neg_shift_lut[12] = 5'd20;
        neg_shift_lut[13] = 5'd19;
        neg_shift_lut[14] = 5'd18;
        neg_shift_lut[15] = 5'd17;
        neg_shift_lut[16] = 5'd16;
        neg_shift_lut[17] = 5'd15;
        neg_shift_lut[18] = 5'd14;
        neg_shift_lut[19] = 5'd13;
        neg_shift_lut[20] = 5'd12;
        neg_shift_lut[21] = 5'd11;
        neg_shift_lut[22] = 5'd10;
        neg_shift_lut[23] = 5'd 9;
        neg_shift_lut[24] = 5'd 8;
        neg_shift_lut[25] = 5'd 7;
        neg_shift_lut[26] = 5'd 6;
        neg_shift_lut[27] = 5'd 5;
        neg_shift_lut[28] = 5'd 4;
        neg_shift_lut[29] = 5'd 3;
        neg_shift_lut[30] = 5'd 2;
        neg_shift_lut[31] = 5'd 1;
    end

    assign shift_direction = shift[4];
    assign shift_amount_lut = neg_shift_lut[shift];

    // Expanded: assign shift_amount = shift_direction ? shift_amount_lut : shift;
    wire [4:0] shift_amount_internal;
    assign shift_amount_internal = 5'b0;
    assign shift_amount = shift_amount_internal;
    generate
        genvar i;
        for (i = 0; i < 5; i = i + 1) begin : gen_shift_amount
            assign shift_amount_internal[i] = (shift_direction) ? shift_amount_lut[i] : shift[i];
        end
    endgenerate

    // Expanded: assign out = shift_direction ? (in << shift_amount) : (in >> shift_amount);
    reg [W-1:0] out_reg;
    always @(*) begin
        if (shift_direction) begin
            out_reg = in << shift_amount;
        end else begin
            out_reg = in >> shift_amount;
        end
    end
    assign out = out_reg;

endmodule