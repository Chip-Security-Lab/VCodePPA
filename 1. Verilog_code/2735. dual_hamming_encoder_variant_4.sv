//SystemVerilog
module dual_hamming_encoder(
    input clk, rst_n,
    input [3:0] data_a, data_b,
    input valid_in,
    output reg valid_out,
    output reg [6:0] encoded_a, encoded_b
);
    // Stage 1 registers - input data and control
    reg [3:0] data_a_stage1, data_b_stage1;
    reg valid_stage1;
    
    // Stage 2 registers - partial computation results
    reg p0_a_stage2, p1_a_stage2, p3_a_stage2;
    reg p0_b_stage2, p1_b_stage2, p3_b_stage2;
    reg [3:0] data_a_stage2, data_b_stage2;
    reg valid_stage2;
    
    // Pipeline Stage 1: Register inputs and compute parity bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_stage1 <= 4'b0;
            data_b_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_a_stage1 <= data_a;
            data_b_stage1 <= data_b;
            valid_stage1 <= valid_in;
        end
    end
    
    // Pipeline Stage 2: Compute parity bits and pass data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p0_a_stage2 <= 1'b0;
            p1_a_stage2 <= 1'b0;
            p3_a_stage2 <= 1'b0;
            p0_b_stage2 <= 1'b0;
            p1_b_stage2 <= 1'b0;
            p3_b_stage2 <= 1'b0;
            data_a_stage2 <= 4'b0;
            data_b_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
        end else begin
            // Compute parity bits for channel A
            p0_a_stage2 <= data_a_stage1[0] ^ data_a_stage1[1] ^ data_a_stage1[3];
            p1_a_stage2 <= data_a_stage1[0] ^ data_a_stage1[2] ^ data_a_stage1[3];
            p3_a_stage2 <= data_a_stage1[1] ^ data_a_stage1[2] ^ data_a_stage1[3];
            
            // Compute parity bits for channel B
            p0_b_stage2 <= data_b_stage1[0] ^ data_b_stage1[1] ^ data_b_stage1[3];
            p1_b_stage2 <= data_b_stage1[0] ^ data_b_stage1[2] ^ data_b_stage1[3];
            p3_b_stage2 <= data_b_stage1[1] ^ data_b_stage1[2] ^ data_b_stage1[3];
            
            // Pass along the data bits
            data_a_stage2 <= data_a_stage1;
            data_b_stage2 <= data_b_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline Stage 3: Assemble final encoded output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_a <= 7'b0;
            encoded_b <= 7'b0;
            valid_out <= 1'b0;
        end else begin
            if (valid_stage2) begin
                // Assemble final encoded word for channel A
                encoded_a[0] <= p0_a_stage2;              // Parity bit P0
                encoded_a[1] <= p1_a_stage2;              // Parity bit P1
                encoded_a[2] <= data_a_stage2[0];         // Data bit D0
                encoded_a[3] <= p3_a_stage2;              // Parity bit P3
                encoded_a[4] <= data_a_stage2[1];         // Data bit D1
                encoded_a[5] <= data_a_stage2[2];         // Data bit D2
                encoded_a[6] <= data_a_stage2[3];         // Data bit D3
                
                // Assemble final encoded word for channel B
                encoded_b[0] <= p0_b_stage2;              // Parity bit P0
                encoded_b[1] <= p1_b_stage2;              // Parity bit P1
                encoded_b[2] <= data_b_stage2[0];         // Data bit D0
                encoded_b[3] <= p3_b_stage2;              // Parity bit P3
                encoded_b[4] <= data_b_stage2[1];         // Data bit D1
                encoded_b[5] <= data_b_stage2[2];         // Data bit D2
                encoded_b[6] <= data_b_stage2[3];         // Data bit D3
            end
            valid_out <= valid_stage2;
        end
    end
endmodule