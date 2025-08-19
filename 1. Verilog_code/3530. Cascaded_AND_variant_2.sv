//SystemVerilog
module Cascaded_AND (
    input wire clk,      // Clock signal
    input wire rst_n,    // Active-low reset
    input wire [2:0] in, // Input signals
    output reg out       // Registered output
);
    // Clock buffering for high fanout reduction
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // Clock buffering - distribute load across multiple buffers
    assign clk_buf1 = clk;  // Buffer for first stage
    assign clk_buf2 = clk;  // Buffer for second stage
    assign clk_buf3 = clk;  // Buffer for third stage
    
    // Pipeline registers
    reg [2:0] in_stage1;
    
    // Buffered copies of in_stage1 to reduce fanout
    reg [2:0] in_stage1_buf1; // For stage1_result computation
    reg [2:0] in_stage1_buf2; // For final output computation
    
    reg stage1_result;
    
    // First pipeline stage - register inputs
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n)
            in_stage1 <= 3'b000;
        else
            in_stage1 <= in;
    end
    
    // Buffer the high fanout in_stage1 signal
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            in_stage1_buf1 <= 3'b000;
            in_stage1_buf2 <= 3'b000;
        end
        else begin
            in_stage1_buf1 <= in_stage1;
            in_stage1_buf2 <= in_stage1;
        end
    end
    
    // Second pipeline stage - compute first AND and register result
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n)
            stage1_result <= 1'b0;
        else
            stage1_result <= in_stage1_buf1[0] & in_stage1_buf1[1];
    end
    
    // Third pipeline stage - compute final result
    always @(posedge clk_buf3 or negedge rst_n) begin
        if (!rst_n)
            out <= 1'b0;
        else
            out <= stage1_result & in_stage1_buf2[2];
    end
endmodule