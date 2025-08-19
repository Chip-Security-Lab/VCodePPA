//SystemVerilog
module hamming16_fast_encoder(
    input wire clk,              // Added clock for pipelining
    input wire rst_n,            // Added reset for pipeline registers
    input wire [15:0] raw_data,
    output reg [21:0] encoded_data
);
    // Pipeline stage 1: Raw data capture and initial parity bits
    reg [15:0] data_stage1;
    reg [3:0] parity_bits_s1;
    
    // Pipeline stage 2: Data path preparation
    reg [15:0] data_stage2;
    reg [3:0] parity_bits_s2;
    reg overall_parity_s2;
    
    // Intermediate parity calculation wires
    wire [3:0] parity_calc;
    wire overall_parity;
    
    // Parallel parity calculation for better timing
    assign parity_calc[0] = ^(raw_data & 16'b1010_1010_1010_1010);
    assign parity_calc[1] = ^(raw_data & 16'b1100_1100_1100_1100);
    assign parity_calc[2] = ^(raw_data & 16'b1111_0000_1111_0000);
    assign parity_calc[3] = ^(raw_data & 16'b1111_1111_0000_0000);
    
    // Overall parity calculation
    assign overall_parity = ^{parity_calc[3:0], raw_data};
    
    // Pipeline control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            data_stage1 <= 16'b0;
            parity_bits_s1 <= 4'b0;
            data_stage2 <= 16'b0;
            parity_bits_s2 <= 4'b0;
            overall_parity_s2 <= 1'b0;
            encoded_data <= 22'b0;
        end else begin
            // Stage 1: Capture inputs and first-level parity
            data_stage1 <= raw_data;
            parity_bits_s1 <= parity_calc;
            
            // Stage 2: Forward data and parity bits
            data_stage2 <= data_stage1;
            parity_bits_s2 <= parity_bits_s1;
            overall_parity_s2 <= overall_parity;
            
            // Output stage: Assemble encoded data with proper bit placement
            encoded_data <= {
                data_stage2[15:11], parity_bits_s2[3], 
                data_stage2[10:4], parity_bits_s2[2],
                data_stage2[3:1], parity_bits_s2[1],
                data_stage2[0], parity_bits_s2[0], overall_parity_s2
            };
        end
    end
endmodule