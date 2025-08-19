//SystemVerilog
module Par2SerMux #(parameter DW=8) (
    input clk,
    input load,
    input [DW-1:0] par_in,
    output ser_out
);

    // Buffer registers for high fanout signals
    reg load_buf1, load_buf2;
    reg [DW-1:0] par_in_buf1, par_in_buf2;

    // Shift register
    reg [DW-1:0] shift_reg;

    // Lookup Table for subtraction by 1 (for index calculation)
    wire [7:0] sub_lut [0:255];
    genvar i;
    generate
        for (i=0; i<256; i=i+1) begin : gen_sub_lut
            assign sub_lut[i] = i - 1;
        end
    endgenerate

    // Lookup Table for right shift by 1
    wire [7:0] rshift_lut [0:255];
    generate
        for (i=0; i<256; i=i+1) begin : gen_rshift_lut
            assign rshift_lut[i] = {1'b0, i[7:1]};
        end
    endgenerate

    // Buffer the high fanout 'load' and 'par_in' signals (two-stage buffering)
    always @(posedge clk) begin
        load_buf1 <= load;
        load_buf2 <= load_buf1;
        par_in_buf1 <= par_in;
        par_in_buf2 <= par_in_buf1;
    end

    // Next value selection using LUT for right shift
    wire [DW-1:0] shift_lut_out;
    assign shift_lut_out = rshift_lut[shift_reg];

    always @(posedge clk) begin
        if (load_buf2)
            shift_reg <= par_in_buf2;
        else
            shift_reg <= shift_lut_out;
    end

    assign ser_out = shift_reg[0];

endmodule