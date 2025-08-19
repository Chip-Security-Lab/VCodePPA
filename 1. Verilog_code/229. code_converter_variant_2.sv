//SystemVerilog
module code_converter (
    input [2:0] binary,
    output [2:0] gray,
    output [7:0] one_hot
);
    // Gray code conversion using XOR
    assign gray = binary ^ (binary >> 1);
    
    // One-hot encoder using barrel shifter implementation
    wire [7:0] one_hot_stage0;
    wire [7:0] one_hot_stage1;
    wire [7:0] one_hot_stage2;
    
    // Stage 0: Initial value - 8'b00000001
    assign one_hot_stage0 = 8'b00000001;
    
    // Stage 1: Conditional shift by 1 position
    assign one_hot_stage1 = binary[0] ? {one_hot_stage0[6:0], one_hot_stage0[7]} : one_hot_stage0;
    
    // Stage 2: Conditional shift by 2 positions
    assign one_hot_stage2 = binary[1] ? {one_hot_stage1[5:0], one_hot_stage1[7:6]} : one_hot_stage1;
    
    // Stage 3: Conditional shift by 4 positions
    assign one_hot = binary[2] ? {one_hot_stage2[3:0], one_hot_stage2[7:4]} : one_hot_stage2;
    
endmodule