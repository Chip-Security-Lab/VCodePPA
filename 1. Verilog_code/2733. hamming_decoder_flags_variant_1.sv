//SystemVerilog
module hamming_decoder_flags(
    input clk, rst_n,
    input [11:0] code_word,
    output reg [7:0] data_out,
    output reg error_fixed, double_error
);
    // Buffered code_word signals to reduce fan-out
    reg [11:0] code_word_buf1, code_word_buf2;
    
    // Syndrome calculation registers
    reg [3:0] syndrome;
    
    // Individual syndrome bit calculations
    reg syndrome_bit0, syndrome_bit1, syndrome_bit2, syndrome_bit3;
    
    // Internal syndrome signals for balanced loading
    reg syndrome_parity;
    reg syndrome_valid;
    
    // Input buffering logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_word_buf1 <= 12'b0;
        end else begin
            code_word_buf1 <= code_word;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_word_buf2 <= 12'b0;
        end else begin
            code_word_buf2 <= code_word;
        end
    end
    
    // Syndrome bit 0 calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome_bit0 <= 1'b0;
        end else begin
            syndrome_bit0 <= code_word_buf1[0] ^ code_word_buf1[2] ^ code_word_buf1[4] ^ 
                             code_word_buf1[6] ^ code_word_buf1[8] ^ code_word_buf1[10];
        end
    end
    
    // Syndrome bit 1 calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome_bit1 <= 1'b0;
        end else begin
            syndrome_bit1 <= code_word_buf1[1] ^ code_word_buf1[2] ^ code_word_buf1[5] ^ 
                             code_word_buf1[6] ^ code_word_buf1[9] ^ code_word_buf1[10];
        end
    end
    
    // Syndrome bit 2 calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome_bit2 <= 1'b0;
        end else begin
            syndrome_bit2 <= code_word_buf2[3] ^ code_word_buf2[4] ^ code_word_buf2[5] ^ code_word_buf2[6];
        end
    end
    
    // Syndrome bit 3 calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome_bit3 <= 1'b0;
        end else begin
            syndrome_bit3 <= code_word_buf2[7] ^ code_word_buf2[8] ^ code_word_buf2[9] ^ code_word_buf2[10];
        end
    end
    
    // Combine syndrome bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome <= 4'b0;
        end else begin
            syndrome <= {syndrome_bit3, syndrome_bit2, syndrome_bit1, syndrome_bit0};
        end
    end
    
    // Calculate syndrome properties
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            syndrome_parity <= 1'b0;
            syndrome_valid <= 1'b0;
        end else begin
            syndrome_parity <= syndrome_bit0 ^ syndrome_bit1 ^ syndrome_bit2 ^ syndrome_bit3;
            syndrome_valid <= syndrome_bit0 | syndrome_bit1 | syndrome_bit2 | syndrome_bit3;
        end
    end
    
    // Error detection logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_fixed <= 1'b0;
            double_error <= 1'b0;
        end else begin
            error_fixed <= syndrome_valid && ~(syndrome_parity ^ code_word_buf2[11]);
            double_error <= syndrome_valid && (syndrome_parity ^ code_word_buf2[11]);
        end
    end
    
    // Data output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
        end else begin
            data_out <= {code_word_buf2[10:7], code_word_buf2[6:4], code_word_buf2[2]};
        end
    end
endmodule