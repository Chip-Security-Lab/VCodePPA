//SystemVerilog
module dual_channel_shifter (
    input clk,
    input rst_n,
    input [15:0] ch1, ch2,
    input [3:0] shift,
    output reg [15:0] out1, out2
);

    // Stage 1 registers - Store inputs
    reg [15:0] ch1_stage1, ch2_stage1;
    reg [3:0] shift_stage1;
    
    // Stage 2 registers - Calculate shift amounts
    reg [15:0] ch1_stage2, ch2_stage2;
    reg [3:0] shift_stage2;
    reg [3:0] inv_shift_stage2;
    
    // Stage 3 registers - Left shift operations
    reg [15:0] ch1_left_stage3, ch2_left_stage3;
    reg [15:0] ch1_stage3, ch2_stage3;
    reg [3:0] shift_stage3, inv_shift_stage3;
    
    // Stage 4 registers - Right shift operations
    reg [15:0] ch1_left_stage4, ch1_right_stage4;
    reg [15:0] ch2_left_stage4, ch2_right_stage4;
    
    // Pipeline logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            ch1_stage1 <= 16'b0;
            ch2_stage1 <= 16'b0;
            shift_stage1 <= 4'b0;
            
            ch1_stage2 <= 16'b0;
            ch2_stage2 <= 16'b0;
            shift_stage2 <= 4'b0;
            inv_shift_stage2 <= 4'b0;
            
            ch1_stage3 <= 16'b0;
            ch2_stage3 <= 16'b0;
            ch1_left_stage3 <= 16'b0;
            ch2_left_stage3 <= 16'b0;
            shift_stage3 <= 4'b0;
            inv_shift_stage3 <= 4'b0;
            
            ch1_left_stage4 <= 16'b0;
            ch1_right_stage4 <= 16'b0;
            ch2_left_stage4 <= 16'b0;
            ch2_right_stage4 <= 16'b0;
            
            out1 <= 16'b0;
            out2 <= 16'b0;
        end else begin
            // Stage 1: Store inputs
            ch1_stage1 <= ch1;
            ch2_stage1 <= ch2;
            shift_stage1 <= shift;
            
            // Stage 2: Forward inputs and calculate shift values
            ch1_stage2 <= ch1_stage1;
            ch2_stage2 <= ch2_stage1;
            shift_stage2 <= shift_stage1;
            inv_shift_stage2 <= 16 - shift_stage1;
            
            // Stage 3: Forward values and perform left shifts
            ch1_stage3 <= ch1_stage2;
            ch2_stage3 <= ch2_stage2;
            ch1_left_stage3 <= ch1_stage2 << shift_stage2;
            ch2_left_stage3 <= ch2_stage2 << inv_shift_stage2;
            shift_stage3 <= shift_stage2;
            inv_shift_stage3 <= inv_shift_stage2;
            
            // Stage 4: Perform right shifts and forward left shifts
            ch1_left_stage4 <= ch1_left_stage3;
            ch1_right_stage4 <= ch1_stage3 >> inv_shift_stage3;
            ch2_left_stage4 <= ch2_left_stage3;
            ch2_right_stage4 <= ch2_stage3 >> shift_stage3;
            
            // Stage 5: Combine shifted values for final output
            out1 <= ch1_left_stage4 | ch1_right_stage4;
            out2 <= ch2_left_stage4 | ch2_right_stage4;
        end
    end

endmodule