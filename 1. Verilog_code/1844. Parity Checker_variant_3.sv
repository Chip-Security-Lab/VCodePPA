//SystemVerilog
module parity_checker #(
    parameter WIDTH = 8
)(
    input  wire             clk,          // Clock signal
    input  wire             rst_n,        // Active-low reset
    input  wire [WIDTH-1:0] data_in,      // Input data
    input  wire             parity_in,    // Input parity bit
    input  wire             odd_parity_mode, // 1: odd parity, 0: even parity
    output reg              error_flag    // Parity error detection flag
);
    // Pipeline stage 1: Calculate parity
    reg [WIDTH-1:0] data_stage1;
    reg odd_mode_stage1;
    
    // Pipeline stage 2: Partial parity calculation
    reg [3:0] partial_parity_stage2;  // For WIDTH=8 example
    reg odd_mode_stage2;
    
    // Pipeline stage 3: Final parity and comparison
    reg calculated_parity_stage3;
    reg expected_parity_stage3;
    
    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            odd_mode_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            odd_mode_stage1 <= odd_parity_mode;
        end
    end
    
    // Stage 2: Calculate partial parity for reducing logic depth
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partial_parity_stage2 <= 4'b0000;
            odd_mode_stage2 <= 1'b0;
        end else begin
            // Split the XOR tree for better timing
            if (WIDTH == 8) begin
                partial_parity_stage2[0] <= data_stage1[0] ^ data_stage1[1];
                partial_parity_stage2[1] <= data_stage1[2] ^ data_stage1[3];
                partial_parity_stage2[2] <= data_stage1[4] ^ data_stage1[5];
                partial_parity_stage2[3] <= data_stage1[6] ^ data_stage1[7];
            end else begin
                // Parametrized logic would go here for different WIDTH values
                partial_parity_stage2 <= ^data_stage1;
            end
            odd_mode_stage2 <= odd_mode_stage1;
        end
    end
    
    // Stage 3: Complete parity calculation and store expected parity
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            calculated_parity_stage3 <= 1'b0;
            expected_parity_stage3 <= 1'b0;
        end else begin
            // Final parity calculation
            calculated_parity_stage3 <= partial_parity_stage2[0] ^ 
                                       partial_parity_stage2[1] ^ 
                                       partial_parity_stage2[2] ^ 
                                       partial_parity_stage2[3] ^ 
                                       odd_mode_stage2;
            expected_parity_stage3 <= parity_in;
        end
    end
    
    // Output stage: Compare calculated parity with expected parity
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_flag <= 1'b0;
        end else begin
            error_flag <= calculated_parity_stage3 != expected_parity_stage3;
        end
    end
    
endmodule