//SystemVerilog
module async_arith_shift_right (
    input      [15:0] data_i,
    input      [3:0]  shamt_i,
    input             enable_i,
    output reg [15:0] data_o
);
    // Internal signals for optimized barrel shifter implementation
    reg [15:0] shift_stage1, shift_stage2, shift_stage3, shift_stage4;
    wire sign_bit = data_i[15];
    
    // Multi-stage logarithmic barrel shifter with sign extension
    always @(*) begin
        if (enable_i) begin
            // Stage 1: Shift by 0 or 1 bit
            shift_stage1 = shamt_i[0] ? {{1{sign_bit}}, data_i[15:1]} : data_i;
            
            // Stage 2: Shift by 0 or 2 bits
            shift_stage2 = shamt_i[1] ? {{2{sign_bit}}, shift_stage1[15:2]} : shift_stage1;
            
            // Stage 3: Shift by 0 or 4 bits
            shift_stage3 = shamt_i[2] ? {{4{sign_bit}}, shift_stage2[15:4]} : shift_stage2;
            
            // Stage 4: Shift by 0 or 8 bits
            shift_stage4 = shamt_i[3] ? {{8{sign_bit}}, shift_stage3[15:8]} : shift_stage3;
            
            data_o = shift_stage4;
        end else begin
            data_o = data_i; // Pass through when disabled
        end
    end
endmodule