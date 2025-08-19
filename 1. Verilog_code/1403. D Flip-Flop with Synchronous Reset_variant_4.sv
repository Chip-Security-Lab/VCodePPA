//SystemVerilog
module d_ff_pipelined (
    input wire clk,
    input wire rst,
    input wire d,
    input wire valid_in,
    output wire valid_out,
    output wire q
);
    // Stage 1 registers
    reg stage1_data;
    reg stage1_valid;
    
    // Stage 2 registers
    reg stage2_data;
    reg stage2_valid;
    
    // Combined pipeline stages
    always @(posedge clk) begin
        if (rst) begin
            // Reset all pipeline registers
            stage1_data <= 1'b0;
            stage1_valid <= 1'b0;
            stage2_data <= 1'b0;
            stage2_valid <= 1'b0;
        end else begin
            // Pipeline Stage 1
            stage1_data <= d;
            stage1_valid <= valid_in;
            
            // Pipeline Stage 2
            stage2_data <= stage1_data;
            stage2_valid <= stage1_valid;
        end
    end
    
    // Output assignments
    assign q = stage2_data;
    assign valid_out = stage2_valid;
endmodule