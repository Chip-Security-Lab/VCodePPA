//SystemVerilog
module feistel_network #(parameter HALF_WIDTH = 16) (
    input wire clk, rst_n, enable,
    input wire [HALF_WIDTH-1:0] left_in, right_in,
    input wire [HALF_WIDTH-1:0] round_key,
    output reg [HALF_WIDTH-1:0] left_out, right_out
);
    // Stage 1: Input buffering and initial key XOR
    reg [HALF_WIDTH-1:0] right_stage1, left_stage1;
    reg [HALF_WIDTH-1:0] key_stage1;
    reg enable_stage1;
    
    // Stage 2: Partial F function computation (first half)
    reg [HALF_WIDTH-1:0] right_stage2, left_stage2;
    reg [HALF_WIDTH-1:0] f_partial_stage2;
    reg enable_stage2;
    
    // Stage 3: Complete F function and prepare results
    reg [HALF_WIDTH-1:0] right_stage3, left_stage3;
    reg [HALF_WIDTH-1:0] f_output_stage3;
    reg enable_stage3;
    
    // Pipeline Stage 1
    always @(posedge clk) begin
        if (!rst_n) begin
            left_stage1 <= 0;
            right_stage1 <= 0;
            key_stage1 <= 0;
            enable_stage1 <= 0;
        end else begin
            left_stage1 <= left_in;
            right_stage1 <= right_in;
            key_stage1 <= round_key;
            enable_stage1 <= enable;
        end
    end
    
    // Pipeline Stage 2
    always @(posedge clk) begin
        if (!rst_n) begin
            left_stage2 <= 0;
            right_stage2 <= 0;
            f_partial_stage2 <= 0;
            enable_stage2 <= 0;
        end else begin
            left_stage2 <= left_stage1;
            right_stage2 <= right_stage1;
            // First part of F function computation
            f_partial_stage2 <= right_stage1 ^ key_stage1;
            enable_stage2 <= enable_stage1;
        end
    end
    
    // Pipeline Stage 3
    always @(posedge clk) begin
        if (!rst_n) begin
            left_stage3 <= 0;
            right_stage3 <= 0;
            f_output_stage3 <= 0;
            enable_stage3 <= 0;
        end else begin
            left_stage3 <= left_stage2;
            right_stage3 <= right_stage2;
            // Complete F function (in this simple case just passing through)
            f_output_stage3 <= f_partial_stage2;
            enable_stage3 <= enable_stage2;
        end
    end
    
    // Output Stage
    always @(posedge clk) begin
        if (!rst_n) begin
            left_out <= 0;
            right_out <= 0;
        end else if (enable_stage3) begin
            left_out <= right_stage3;
            right_out <= left_stage3 ^ f_output_stage3;
        end
    end
endmodule