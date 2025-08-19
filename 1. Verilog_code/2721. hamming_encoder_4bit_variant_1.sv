//SystemVerilog
module hamming_encoder_4bit(
    input clk, rst_n,
    input valid_in,
    input [3:0] data_in,
    output reg valid_out,
    output reg [6:0] encoded_out,
    output reg ready
);
    // Pipeline stage 1 registers
    reg [3:0] data_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [3:0] data_stage2;
    reg [2:0] parity_stage2; // Store partial parity bits
    reg valid_stage2;

    // Always ready to accept new input when not in reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            ready <= 1'b0;
        else
            ready <= 1'b1;
    end

    // Pipeline Stage 1: Input registration and first parity bit calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end
        else if (valid_in && ready) begin
            data_stage1 <= data_in;
            valid_stage1 <= 1'b1;
        end
        else if (!valid_in) begin
            valid_stage1 <= 1'b0;
        end
    end

    // Pipeline Stage 2: Parity calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 4'b0;
            parity_stage2 <= 3'b0;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            data_stage2 <= data_stage1;
            // Calculate all three parity bits
            parity_stage2[0] <= data_stage1[0] ^ data_stage1[1] ^ data_stage1[3]; // P1
            parity_stage2[1] <= data_stage1[0] ^ data_stage1[2] ^ data_stage1[3]; // P2
            parity_stage2[2] <= data_stage1[1] ^ data_stage1[2] ^ data_stage1[3]; // P4
            valid_stage2 <= valid_stage1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Pipeline Stage 3: Final output assembly
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_out <= 7'b0;
            valid_out <= 1'b0;
        end
        else if (valid_stage2) begin
            // Assemble final encoded output
            encoded_out[0] <= parity_stage2[0];          // P1
            encoded_out[1] <= parity_stage2[1];          // P2
            encoded_out[2] <= data_stage2[0];            // D1
            encoded_out[3] <= parity_stage2[2];          // P4
            encoded_out[4] <= data_stage2[1];            // D2
            encoded_out[5] <= data_stage2[2];            // D3
            encoded_out[6] <= data_stage2[3];            // D4
            valid_out <= valid_stage2;
        end
        else begin
            valid_out <= 1'b0;
        end
    end
endmodule