//SystemVerilog
module bidir_arith_logical_shifter (
    input  [31:0] src,
    input  [4:0]  amount,
    input         direction,  // 0=left, 1=right
    input         arith_mode, // 0=logical, 1=arithmetic
    output [31:0] result
);
    // Barrel shifter implementation with parameterized stages
    wire [31:0] stage_input = src;
    wire [31:0] stage_output;
    wire sign_bit = src[31] & arith_mode;
    
    // Generate different shift masks based on shift direction and arithmetic mode
    wire [31:0] right_fill = {32{sign_bit}};
    wire [31:0] left_fill = 32'b0;
    
    // Implement barrel shifter for better timing and potentially better area
    wire [31:0] stage0, stage1, stage2, stage3, stage4;
    
    // Stage 0: shift by 0 or 1
    assign stage0 = amount[0] ? 
                   (direction ? {(arith_mode & src[31]), src[31:1]} : {src[30:0], 1'b0}) :
                   src;
    
    // Stage 1: shift by 0 or 2
    assign stage1 = amount[1] ? 
                   (direction ? {{2{arith_mode & src[31]}}, stage0[31:2]} : {stage0[29:0], 2'b0}) :
                   stage0;
    
    // Stage 2: shift by 0 or 4
    assign stage2 = amount[2] ? 
                   (direction ? {{4{arith_mode & src[31]}}, stage1[31:4]} : {stage1[27:0], 4'b0}) :
                   stage1;
    
    // Stage 3: shift by 0 or 8
    assign stage3 = amount[3] ? 
                   (direction ? {{8{arith_mode & src[31]}}, stage2[31:8]} : {stage2[23:0], 8'b0}) :
                   stage2;
    
    // Stage 4: shift by 0 or 16
    assign stage4 = amount[4] ? 
                   (direction ? {{16{arith_mode & src[31]}}, stage3[31:16]} : {stage3[15:0], 16'b0}) :
                   stage3;
    
    // Final output
    assign result = stage4;
endmodule