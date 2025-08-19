//SystemVerilog
module preload_shift_reg (
    input clk, load,
    input [3:0] shift,
    input [15:0] load_data,
    output [15:0] shifted
);
    reg [15:0] storage;
    reg [15:0] stage1_left_reg, stage1_right_reg;
    reg [15:0] stage2_left_reg, stage2_right_reg;
    reg [15:0] stage3_left_reg, stage3_right_reg;
    reg [15:0] stage4_left_reg, stage4_right_reg;
    
    wire [15:0] stage1_left, stage1_right;
    wire [15:0] stage2_left, stage2_right;
    wire [15:0] stage3_left, stage3_right;
    wire [15:0] stage4_left, stage4_right;
    
    // Stage 1: Shift by 0 or 1 bit
    assign stage1_left = shift[0] ? {storage[14:0], storage[15]} : storage;
    assign stage1_right = shift[0] ? {storage[0], storage[15:1]} : storage;
    
    // Stage 2: Shift by 0 or 2 bits
    assign stage2_left = shift[1] ? {stage1_left_reg[13:0], stage1_left_reg[15:14]} : stage1_left_reg;
    assign stage2_right = shift[1] ? {stage1_right_reg[1:0], stage1_right_reg[15:2]} : stage1_right_reg;
    
    // Stage 3: Shift by 0 or 4 bits
    assign stage3_left = shift[2] ? {stage2_left_reg[11:0], stage2_left_reg[15:12]} : stage2_left_reg;
    assign stage3_right = shift[2] ? {stage2_right_reg[3:0], stage2_right_reg[15:4]} : stage2_right_reg;
    
    // Stage 4: Shift by 0 or 8 bits
    assign stage4_left = shift[3] ? {stage3_left_reg[7:0], stage3_left_reg[15:8]} : stage3_left_reg;
    assign stage4_right = shift[3] ? {stage3_right_reg[7:0], stage3_right_reg[15:8]} : stage3_right_reg;
    
    // Final result combines left and right shifts
    assign shifted = stage4_left_reg | stage4_right_reg;
    
    always @(posedge clk) begin
        if (load) 
            storage <= load_data;
        else begin
            // Pipeline registers for each stage
            stage1_left_reg <= stage1_left;
            stage1_right_reg <= stage1_right;
            stage2_left_reg <= stage2_left;
            stage2_right_reg <= stage2_right;
            stage3_left_reg <= stage3_left;
            stage3_right_reg <= stage3_right;
            stage4_left_reg <= stage4_left;
            stage4_right_reg <= stage4_right;
        end
    end
endmodule