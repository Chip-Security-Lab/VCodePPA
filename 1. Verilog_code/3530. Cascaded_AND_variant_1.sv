//SystemVerilog
module Cascaded_AND (
    input  wire        clk,       // Clock input
    input  wire        rst_n,     // Active-low reset
    input  wire [2:0]  in,        // Input data
    output reg         out        // Output result
);

    // Balanced pipeline implementation
    // Stage 1: Capture inputs and perform first computation
    reg [2:0] stage1_in;
    reg       stage1_partial;
    
    // Stage 2: Complete the computation
    reg       stage2_result;
    
    // Pipeline stage 1 - capture all inputs at once and start partial computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_in <= 3'b000;
            stage1_partial <= 1'b0;
        end else begin
            stage1_in <= in;
            stage1_partial <= in[0] & in[1];
        end
    end
    
    // Pipeline stage 2 - complete the computation with registered inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            stage2_result <= stage1_partial & stage1_in[2];
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 1'b0;
        end else begin
            out <= stage2_result;
        end
    end

endmodule