//SystemVerilog
module async_hamming_enc_8bit(
    input wire clk,
    input wire rst_n,
    input wire valid,
    output reg ready,
    input wire [7:0] din,
    output reg [11:0] enc_out
);
    // Internal pipeline registers
    reg [7:0] din_stage1;
    reg [7:0] din_stage2;
    reg valid_stage1;
    reg valid_stage2;
    
    // Intermediate parity calculations
    wire [4:0] parity_bits_stage1;
    reg [4:0] parity_bits_stage2;
    
    // Data flow path stage 1 - Initial parity calculations
    assign parity_bits_stage1[0] = din[0] ^ din[1] ^ din[3] ^ din[4] ^ din[6];  // P0
    assign parity_bits_stage1[1] = din[0] ^ din[2] ^ din[3] ^ din[5] ^ din[6];  // P1
    assign parity_bits_stage1[2] = din[1] ^ din[2] ^ din[3] ^ din[7];           // P3
    assign parity_bits_stage1[3] = 1'b0;  // Placeholder for overall parity
    assign parity_bits_stage1[4] = 1'b0;  // Placeholder
    
    // Pipeline stage 1 - Register partial results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage1 <= 8'b0;
            parity_bits_stage2 <= 5'b0;
            valid_stage1 <= 1'b0;
        end else begin
            din_stage1 <= din;
            parity_bits_stage2 <= parity_bits_stage1;
            valid_stage1 <= valid;
        end
    end
    
    // Pipeline stage 2 - Continue registering data path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            din_stage2 <= din_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Ready signal generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b0;
        end else begin
            ready <= ~valid_stage2;
        end
    end
    
    // Final stage - Assemble encoded output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enc_out <= 12'b0;
        end else if (valid_stage2) begin
            // Parity bits
            enc_out[0] <= parity_bits_stage2[0];  // P0
            enc_out[1] <= parity_bits_stage2[1];  // P1
            enc_out[3] <= parity_bits_stage2[2];  // P3
            
            // Data bits mapped to Hamming code positions
            enc_out[2] <= din_stage2[0];   // D0
            enc_out[4] <= din_stage2[1];   // D1
            enc_out[5] <= din_stage2[2];   // D2
            enc_out[6] <= din_stage2[3];   // D3
            enc_out[7] <= din_stage2[4];   // D4
            enc_out[8] <= din_stage2[5];   // D5
            enc_out[9] <= din_stage2[6];   // D6
            enc_out[10] <= din_stage2[7];  // D7
            
            // Overall parity for SEC-DED
            enc_out[11] <= din_stage2[0] ^ din_stage2[1] ^ din_stage2[2] ^ din_stage2[3] ^ 
                          din_stage2[4] ^ din_stage2[5] ^ din_stage2[6] ^ din_stage2[7] ^
                          parity_bits_stage2[0] ^ parity_bits_stage2[1] ^ parity_bits_stage2[2];
        end
    end
endmodule