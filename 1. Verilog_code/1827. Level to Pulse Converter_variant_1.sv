//SystemVerilog
module level2pulse_converter (
    input  wire clk_i,
    input  wire rst_i,  // Active high reset
    input  wire level_i,
    output reg  pulse_o
);

    // Pipeline registers
    reg level_stage1;
    reg level_stage2;
    reg pulse_stage1;
    
    // Stage 1: Input sampling and edge detection
    always @(posedge clk_i) begin
        if (rst_i) begin
            level_stage1 <= 1'b0;
            pulse_stage1 <= 1'b0;
        end else begin
            level_stage1 <= level_i;
            pulse_stage1 <= level_i & ~level_stage1;
        end
    end

    // Stage 2: Output generation
    always @(posedge clk_i) begin
        if (rst_i) begin
            level_stage2 <= 1'b0;
            pulse_o <= 1'b0;
        end else begin
            level_stage2 <= level_stage1;
            pulse_o <= pulse_stage1;
        end
    end

endmodule