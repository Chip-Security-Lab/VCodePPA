//SystemVerilog
module sync_reset_dist(
    input wire clk,
    input wire rst_in,
    output reg [7:0] rst_out
);
    // Stage 1 registers
    reg rst_in_stage1;
    reg [3:0] rst_out_stage1_upper;
    
    // Stage 2 registers
    reg rst_in_stage2;
    reg [3:0] rst_out_stage1_lower;
    
    // Combined pipeline logic with the same clock trigger
    always @(posedge clk) begin
        // First pipeline stage - capture input and process upper bits
        rst_in_stage1 <= rst_in;
        rst_out_stage1_upper <= rst_in ? 4'hF : 4'h0;  // Upper 4 bits
        
        // Second pipeline stage - propagate control and process lower bits
        rst_in_stage2 <= rst_in_stage1;
        rst_out_stage1_lower <= rst_in_stage1 ? 4'hF : 4'h0;  // Lower 4 bits
        
        // Final stage - combine results
        rst_out <= {rst_out_stage1_upper, rst_out_stage1_lower};
    end
endmodule