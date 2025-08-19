//SystemVerilog
module hamm_codec(
    input t_clk, t_rst,
    input [3:0] i_data,
    input i_encode_n_decode,
    output reg [6:0] o_encoded,
    output reg [3:0] o_decoded,
    output reg o_error
);
    // Input stage buffers (stage 1)
    reg [3:0] i_data_stage1, i_data_stage2;
    reg i_encode_n_decode_stage1, i_encode_n_decode_stage2, i_encode_n_decode_stage3;
    
    // Intermediate calculation registers for encoding (stage 2)
    reg p1_stage2, p2_stage2, p3_stage2;
    reg [3:0] data_bits_stage2;
    
    // Encoded data pipeline registers (stage 3)
    reg [6:0] encoded_stage3;
    reg [6:0] o_encoded_buf_stage1, o_encoded_buf_stage2;
    
    // Syndrome calculation split into multiple stages
    reg [2:0] syndrome_partial_stage1; // First stage of syndrome
    reg [2:0] syndrome_stage2;         // Second stage of syndrome
    reg [2:0] syndrome_stage3;         // Final syndrome
    
    // Error detection pipeline
    reg error_stage3;
    
    // Decoded data pipeline
    reg [3:0] decoded_stage3;
    
    // Stage 1: Input buffering and initial calculations
    always @(posedge t_clk or posedge t_rst) begin
        if (t_rst) begin
            i_data_stage1 <= 4'b0;
            i_data_stage2 <= 4'b0;
            i_encode_n_decode_stage1 <= 1'b0;
            o_encoded_buf_stage1 <= 7'b0;
        end else begin
            i_data_stage1 <= i_data;
            i_data_stage2 <= i_data;
            i_encode_n_decode_stage1 <= i_encode_n_decode;
            o_encoded_buf_stage1 <= o_encoded;
        end
    end
    
    // Stage 2: Parity bit calculation and syndrome first stage
    always @(posedge t_clk or posedge t_rst) begin
        if (t_rst) begin
            p1_stage2 <= 1'b0;
            p2_stage2 <= 1'b0;
            p3_stage2 <= 1'b0;
            data_bits_stage2 <= 4'b0;
            i_encode_n_decode_stage2 <= 1'b0;
            o_encoded_buf_stage2 <= 7'b0;
            syndrome_partial_stage1 <= 3'b0;
        end else begin
            // Parity bits pre-calculation for encode path
            p1_stage2 <= i_data_stage1[0] ^ i_data_stage1[1] ^ i_data_stage1[3];
            p2_stage2 <= i_data_stage1[0] ^ i_data_stage1[2] ^ i_data_stage1[3];
            p3_stage2 <= i_data_stage1[1] ^ i_data_stage1[2] ^ i_data_stage1[3];
            data_bits_stage2 <= i_data_stage2;
            
            // Control signal propagation
            i_encode_n_decode_stage2 <= i_encode_n_decode_stage1;
            
            // Buffer for encoded data used in decode path
            o_encoded_buf_stage2 <= o_encoded_buf_stage1;
            
            // First stage of syndrome calculation (partial XORs)
            syndrome_partial_stage1[0] <= o_encoded_buf_stage1[0] ^ o_encoded_buf_stage1[2];
            syndrome_partial_stage1[1] <= o_encoded_buf_stage1[1] ^ o_encoded_buf_stage1[2];
            syndrome_partial_stage1[2] <= o_encoded_buf_stage1[3] ^ o_encoded_buf_stage1[4];
        end
    end
    
    // Stage 3: Final calculations and results preparation
    always @(posedge t_clk or posedge t_rst) begin
        if (t_rst) begin
            syndrome_stage2 <= 3'b0;
            syndrome_stage3 <= 3'b0;
            i_encode_n_decode_stage3 <= 1'b0;
            encoded_stage3 <= 7'b0;
            error_stage3 <= 1'b0;
            decoded_stage3 <= 4'b0;
        end else begin
            // Complete syndrome calculation
            syndrome_stage2[0] <= syndrome_partial_stage1[0] ^ o_encoded_buf_stage2[4] ^ o_encoded_buf_stage2[6];
            syndrome_stage2[1] <= syndrome_partial_stage1[1] ^ o_encoded_buf_stage2[5] ^ o_encoded_buf_stage2[6];
            syndrome_stage2[2] <= syndrome_partial_stage1[2] ^ o_encoded_buf_stage2[5] ^ o_encoded_buf_stage2[6];
            
            // Final syndrome
            syndrome_stage3 <= syndrome_stage2;
            
            // Control signal propagation
            i_encode_n_decode_stage3 <= i_encode_n_decode_stage2;
            
            // Prepare encoded data
            encoded_stage3[0] <= p1_stage2;
            encoded_stage3[1] <= p2_stage2;
            encoded_stage3[2] <= data_bits_stage2[0];
            encoded_stage3[3] <= p3_stage2;
            encoded_stage3[4] <= data_bits_stage2[1];
            encoded_stage3[5] <= data_bits_stage2[2];
            encoded_stage3[6] <= data_bits_stage2[3];
            
            // Prepare decoded data (just pass through the data bits)
            decoded_stage3 <= {o_encoded_buf_stage2[6], o_encoded_buf_stage2[5], 
                              o_encoded_buf_stage2[4], o_encoded_buf_stage2[2]};
            
            // Error detection
            error_stage3 <= |syndrome_stage2;
        end
    end
    
    // Output stage: Final selection based on mode
    always @(posedge t_clk or posedge t_rst) begin
        if (t_rst) begin
            o_encoded <= 7'b0;
            o_decoded <= 4'b0;
            o_error <= 1'b0;
        end else if (i_encode_n_decode_stage3) begin
            // Encode operation output
            o_encoded <= encoded_stage3;
        end else begin
            // Decode operation output
            o_decoded <= decoded_stage3;
            o_error <= error_stage3;
        end
    end
endmodule