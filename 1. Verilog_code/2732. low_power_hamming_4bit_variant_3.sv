//SystemVerilog
module low_power_hamming_4bit(
    input clk, sleep_mode,
    input [3:0] data,
    input valid_in,
    output reg valid_out,
    output reg [6:0] encoded
);
    // Power-gated clock
    wire power_save_clk;
    assign power_save_clk = clk & ~sleep_mode;
    
    // Pipeline stage 1 registers
    reg [3:0] data_stage1;
    reg valid_stage1;
    reg [1:0] parity_bits_stage1; // First two parity bits computed in stage 1
    
    // Pipeline stage 2 registers
    reg [3:0] data_stage2;
    reg valid_stage2;
    reg [1:0] parity_bits_stage2;
    reg parity_bit3_stage2; // Third parity bit computed in stage 2
    
    // Pipeline stage 1: Store input data and compute first two parity bits
    always @(posedge power_save_clk) begin
        if (sleep_mode) begin
            data_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
            parity_bits_stage1 <= 2'b0;
        end
        else begin
            data_stage1 <= data;
            valid_stage1 <= valid_in;
            
            // Compute parity bits 0 and 1 in stage 1
            parity_bits_stage1[0] <= data[0] ^ data[1] ^ data[3];
            parity_bits_stage1[1] <= data[0] ^ data[2] ^ data[3];
        end
    end
    
    // Pipeline stage 2: Pass data and compute remaining parity bit
    always @(posedge power_save_clk) begin
        if (sleep_mode) begin
            data_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
            parity_bits_stage2 <= 2'b0;
            parity_bit3_stage2 <= 1'b0;
        end
        else begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
            parity_bits_stage2 <= parity_bits_stage1;
            
            // Compute parity bit 3 in stage 2
            parity_bit3_stage2 <= data_stage1[1] ^ data_stage1[2] ^ data_stage1[3];
        end
    end
    
    // Final stage: Assemble the encoded output
    always @(posedge power_save_clk) begin
        if (sleep_mode) begin
            encoded <= 7'b0;
            valid_out <= 1'b0;
        end
        else begin
            valid_out <= valid_stage2;
            
            // Assemble final encoded output with parity bits and data bits
            encoded[0] <= parity_bits_stage2[0];          // Parity bit 0
            encoded[1] <= parity_bits_stage2[1];          // Parity bit 1
            encoded[2] <= data_stage2[0];                 // Data bit 0
            encoded[3] <= parity_bit3_stage2;             // Parity bit 3
            encoded[4] <= data_stage2[1];                 // Data bit 1
            encoded[5] <= data_stage2[2];                 // Data bit 2
            encoded[6] <= data_stage2[3];                 // Data bit 3
        end
    end
endmodule