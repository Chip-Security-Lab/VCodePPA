//SystemVerilog - IEEE 1364-2005
module enc_4b5b (
    input wire clk, rst_n,
    input wire encode_mode, // 1=encode, 0=decode
    input wire [3:0] data_in,
    input wire [4:0] code_in,
    
    // Valid-Ready handshake signals for input
    input wire in_valid,
    output reg in_ready,
    
    // Valid-Ready handshake signals for output
    output reg out_valid,
    input wire out_ready,
    
    output reg [4:0] code_out,
    output reg [3:0] data_out,
    output reg code_err
);
    // 4B/5B encoding table - optimized ROM structure
    reg [4:0] enc_lut [0:15];
    
    // Decoding table optimized with one-hot approach
    reg [15:0] dec_map [0:31];
    
    // Pipeline registers for improved timing
    reg encode_mode_r;
    reg [3:0] data_in_r;
    reg [4:0] code_in_r;
    
    // State registers for controlling data flow
    reg processing_data;
    reg output_valid_data;
    
    initial begin
        // Encoding lookup table
        enc_lut[4'h0] = 5'b11110; // 0 -> 0x1E
        enc_lut[4'h1] = 5'b01001; // 1 -> 0x09
        enc_lut[4'h2] = 5'b10100; // 2 -> 0x14
        enc_lut[4'h3] = 5'b10101; // 3 -> 0x15
        enc_lut[4'h4] = 5'b01010; // 4 -> 0x0A
        enc_lut[4'h5] = 5'b01011; // 5 -> 0x0B
        enc_lut[4'h6] = 5'b01110; // 6 -> 0x0E
        enc_lut[4'h7] = 5'b01111; // 7 -> 0x0F
        enc_lut[4'h8] = 5'b10010; // 8 -> 0x12
        enc_lut[4'h9] = 5'b10011; // 9 -> 0x13
        enc_lut[4'hA] = 5'b10110; // A -> 0x16
        enc_lut[4'hB] = 5'b10111; // B -> 0x17
        enc_lut[4'hC] = 5'b11010; // C -> 0x1A
        enc_lut[4'hD] = 5'b11011; // D -> 0x1B
        enc_lut[4'hE] = 5'b11100; // E -> 0x1C
        enc_lut[4'hF] = 5'b11101; // F -> 0x1D
        
        // Initialize decoding map (combines validity check and value in single lookup)
        // Default all entries to 0 (invalid)
        for (int i = 0; i < 32; i = i + 1) begin
            dec_map[i] = 16'h0000;
        end
        
        // Set valid entries with one-hot encoding of decoded value
        dec_map[5'h1E] = 16'h0001; // 0
        dec_map[5'h09] = 16'h0002; // 1
        dec_map[5'h14] = 16'h0004; // 2
        dec_map[5'h15] = 16'h0008; // 3
        dec_map[5'h0A] = 16'h0010; // 4
        dec_map[5'h0B] = 16'h0020; // 5
        dec_map[5'h0E] = 16'h0040; // 6
        dec_map[5'h0F] = 16'h0080; // 7
        dec_map[5'h12] = 16'h0100; // 8
        dec_map[5'h13] = 16'h0200; // 9
        dec_map[5'h16] = 16'h0400; // A
        dec_map[5'h17] = 16'h0800; // B
        dec_map[5'h1A] = 16'h1000; // C
        dec_map[5'h1B] = 16'h2000; // D
        dec_map[5'h1C] = 16'h4000; // E
        dec_map[5'h1D] = 16'h8000; // F
    end
    
    // Combinational logic for decoding with priority encoder
    function [3:0] one_hot_to_binary;
        input [15:0] one_hot_val;
        begin
            casez (one_hot_val)
                16'b????_????_????_???1: one_hot_to_binary = 4'h0;
                16'b????_????_????_??1?: one_hot_to_binary = 4'h1;
                16'b????_????_????_?1??: one_hot_to_binary = 4'h2;
                16'b????_????_????_1???: one_hot_to_binary = 4'h3;
                16'b????_????_???1_????: one_hot_to_binary = 4'h4;
                16'b????_????_??1?_????: one_hot_to_binary = 4'h5;
                16'b????_????_?1??_????: one_hot_to_binary = 4'h6;
                16'b????_????_1???_????: one_hot_to_binary = 4'h7;
                16'b????_???1_????_????: one_hot_to_binary = 4'h8;
                16'b????_??1?_????_????: one_hot_to_binary = 4'h9;
                16'b????_?1??_????_????: one_hot_to_binary = 4'hA;
                16'b????_1???_????_????: one_hot_to_binary = 4'hB;
                16'b???1_????_????_????: one_hot_to_binary = 4'hC;
                16'b??1?_????_????_????: one_hot_to_binary = 4'hD;
                16'b?1??_????_????_????: one_hot_to_binary = 4'hE;
                16'b1???_????_????_????: one_hot_to_binary = 4'hF;
                default: one_hot_to_binary = 4'h0;
            endcase
        end
    endfunction
    
    wire [15:0] decoded_one_hot = dec_map[code_in_r];
    wire is_valid_code = |decoded_one_hot;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset pipelined inputs
            encode_mode_r <= 1'b0;
            data_in_r <= 4'b0;
            code_in_r <= 5'b0;
            
            // Reset outputs
            code_out <= 5'b0;
            data_out <= 4'b0;
            code_err <= 1'b0;
            
            // Reset handshake signals
            in_ready <= 1'b1;
            out_valid <= 1'b0;
            
            // Reset state registers
            processing_data <= 1'b0;
            output_valid_data <= 1'b0;
        end else begin
            // Input handshaking logic
            if (in_valid && in_ready) begin
                // Register inputs when valid data is available and we're ready
                encode_mode_r <= encode_mode;
                data_in_r <= data_in;
                code_in_r <= code_in;
                processing_data <= 1'b1;
                in_ready <= 1'b0; // Stop accepting new data until current one is processed
            end
            
            // Process the data
            if (processing_data) begin
                processing_data <= 1'b0;
                output_valid_data <= 1'b1;
                
                // Compute output based on mode
                if (encode_mode_r) begin
                    // Encoding operation (directly from LUT)
                    code_out <= enc_lut[data_in_r];
                    code_err <= 1'b0;
                end else begin
                    // Decoding operation with optimized logic
                    data_out <= one_hot_to_binary(decoded_one_hot);
                    code_err <= !is_valid_code;
                end
            end
            
            // Output handshaking logic
            if (output_valid_data) begin
                out_valid <= 1'b1;
            end
            
            if (out_valid && out_ready) begin
                out_valid <= 1'b0;
                output_valid_data <= 1'b0;
                in_ready <= 1'b1; // Ready to accept new input
            end
        end
    end
endmodule