//SystemVerilog
//========================================================================
//========================================================================
// Top level module with optimized data path structure
module async_rgb565_codec (
    input [23:0] rgb_in,
    input alpha_en,
    output [15:0] rgb565_out
);
    // Pipeline stage 1: Extract and register RGB components
    reg [4:0] red_stage1;
    reg [5:0] green_stage1;
    reg [4:0] blue_stage1;
    
    // Pipeline stage 2: Pack RGB components
    reg [15:0] rgb_packed_stage2;
    
    // Primary data path flow
    always @(*) begin
        // Stage 1: Color extraction
        red_stage1 = rgb_in[23:19];
        green_stage1 = rgb_in[15:10];
        blue_stage1 = rgb_in[7:3];
        
        // Stage 2: RGB packing into 565 format
        rgb_packed_stage2 = {red_stage1, green_stage1, blue_stage1};
    end
    
    // Final output stage: Alpha handling
    assign rgb565_out = alpha_en ? {1'b1, rgb_packed_stage2[14:0]} : rgb_packed_stage2;
    
endmodule