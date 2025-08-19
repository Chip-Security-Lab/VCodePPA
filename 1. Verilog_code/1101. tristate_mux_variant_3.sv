//SystemVerilog
module tristate_mux (
    input wire signed [7:0] source_a, 
    input wire signed [7:0] source_b, 
    input wire select,
    input wire output_enable,
    output wire [7:0] data_bus
);

reg signed [7:0] mux_result;
reg mux_result_en;

// Barrel shifter: logical left shift
function [15:0] barrel_shift_left;
    input [15:0] data_in;
    input [3:0] shift_amt;
    reg [15:0] stage0, stage1, stage2, stage3;
begin
    // Stage 0: shift by 1 if shift_amt[0]
    stage0 = shift_amt[0] ? {data_in[14:0], 1'b0} : data_in;
    // Stage 1: shift by 2 if shift_amt[1]
    stage1 = shift_amt[1] ? {stage0[13:0], 2'b00} : stage0;
    // Stage 2: shift by 4 if shift_amt[2]
    stage2 = shift_amt[2] ? {stage1[11:0], 4'b0000} : stage1;
    // Stage 3: shift by 8 if shift_amt[3]
    stage3 = shift_amt[3] ? {stage2[7:0], 8'b00000000} : stage2;
    barrel_shift_left = stage3;
end
endfunction

// Barrel shifter: arithmetic right shift (for signed values)
function signed [15:0] barrel_shift_arith_right;
    input signed [15:0] data_in;
    input [3:0] shift_amt;
    reg signed [15:0] stage0, stage1, stage2, stage3;
begin
    // Stage 0: shift by 1 if shift_amt[0]
    stage0 = shift_amt[0] ? {data_in[15], data_in[15:1]} : data_in;
    // Stage 1: shift by 2 if shift_amt[1]
    stage1 = shift_amt[1] ? {{2{stage0[15]}}, stage0[15:2]} : stage0;
    // Stage 2: shift by 4 if shift_amt[2]
    stage2 = shift_amt[2] ? {{4{stage1[15]}}, stage1[15:4]} : stage1;
    // Stage 3: shift by 8 if shift_amt[3]
    stage3 = shift_amt[3] ? {{8{stage2[15]}}, stage2[15:8]} : stage2;
    barrel_shift_arith_right = stage3;
end
endfunction

// Optimized signed multiplier function (Booth's Algorithm for 8-bit signed multiply) using barrel shifters
function signed [7:0] signed_mul8_opt;
    input signed [7:0] a;
    input signed [7:0] b;
    reg signed [15:0] product;
    reg [3:0] i;
    reg signed [15:0] mcand;
    reg signed [15:0] mplier;
    reg mplier_last;
begin
    product = 16'b0;
    mcand = { {8{a[7]}}, a };
    mplier = { b, 8'b0 };
    mplier_last = 1'b0;
    for (i = 0; i < 8; i = i + 1) begin
        if ({mplier[0], mplier_last} == 2'b01)
            product = product + mcand;
        else if ({mplier[0], mplier_last} == 2'b10)
            product = product - mcand;
        mplier_last = mplier[0];
        mplier = barrel_shift_arith_right(mplier, 1);
        mcand = barrel_shift_left(mcand, 1);
    end
    signed_mul8_opt = product[7:0];
end
endfunction

always @(*) begin
    if (output_enable) begin
        mux_result_en = 1'b1;
        if (select) begin
            mux_result = signed_mul8_opt(source_b, 8'sd1);
        end else begin
            mux_result = signed_mul8_opt(source_a, 8'sd1);
        end
    end else begin
        mux_result_en = 1'b0;
        mux_result = 8'sd0;
    end
end

assign data_bus = mux_result_en ? mux_result : 8'bz;

endmodule