//SystemVerilog - IEEE 1364-2005
module pcm_codec #(parameter DATA_WIDTH = 16)
(
    input wire clk, rst_n, 
    input wire [DATA_WIDTH-1:0] pcm_in,     // PCM input samples
    input wire [7:0] compressed_in,         // Compressed input
    input wire encode_mode,                 // 1=encode, 0=decode
    output reg [7:0] compressed_out,        // Compressed output
    output reg [DATA_WIDTH-1:0] pcm_out,    // PCM output samples
    output reg data_valid
);
    // μ-law compression constants
    localparam BIAS = 33;
    localparam SEG_SHIFT = 4;
    
    reg [DATA_WIDTH-1:0] abs_sample;
    reg [3:0] segment;
    reg sign;
    
    // Find the segment using priority encoder logic
    function [3:0] find_segment;
        input [DATA_WIDTH-1:0] val;
        begin
            if (val == {DATA_WIDTH{1'b0}}) begin
                find_segment = 4'h0;
            end
            else if (val[DATA_WIDTH-1:DATA_WIDTH-8] != 0) begin
                find_segment = 4'h7;
            end
            else if (val[DATA_WIDTH-1:DATA_WIDTH-7] != 0) begin
                find_segment = 4'h6;
            end
            else if (val[DATA_WIDTH-1:DATA_WIDTH-6] != 0) begin
                find_segment = 4'h5;
            end
            else if (val[DATA_WIDTH-1:DATA_WIDTH-5] != 0) begin
                find_segment = 4'h4;
            end
            else if (val[DATA_WIDTH-1:DATA_WIDTH-4] != 0) begin
                find_segment = 4'h3;
            end
            else if (val[DATA_WIDTH-1:DATA_WIDTH-3] != 0) begin
                find_segment = 4'h2;
            end
            else if (val[DATA_WIDTH-1:DATA_WIDTH-2] != 0) begin
                find_segment = 4'h1;
            end
            else begin
                find_segment = 4'h0;
            end
        end
    endfunction
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compressed_out <= 8'h00;
            pcm_out <= {DATA_WIDTH{1'b0}};
            data_valid <= 1'b0;
        end else begin
            // Use if-else structure for operating mode
            if (encode_mode == 1'b1) begin  // Encode mode
                if (pcm_in[DATA_WIDTH-1] == 1'b1) begin
                    sign = 1'b1;
                    abs_sample = ~pcm_in + 1'b1;
                end else begin
                    sign = 1'b0;
                    abs_sample = pcm_in;
                end
                
                // Find segment using function
                segment = find_segment(abs_sample + BIAS);
                
                // Calculate mantissa based on segment
                if (segment == 4'h0) begin
                    compressed_out <= {sign, 7'b0000000};
                end
                else if (segment == 4'h1) begin
                    compressed_out <= {sign, 1'b0, segment, abs_sample[6:4]};
                end
                else if (segment == 4'h2) begin
                    compressed_out <= {sign, 1'b0, segment, abs_sample[7:5]};
                end
                else if (segment == 4'h3) begin
                    compressed_out <= {sign, 1'b0, segment, abs_sample[8:6]};
                end
                else if (segment == 4'h4) begin
                    compressed_out <= {sign, 1'b0, segment, abs_sample[9:7]};
                end
                else if (segment == 4'h5) begin
                    compressed_out <= {sign, 1'b0, segment, abs_sample[10:8]};
                end
                else if (segment == 4'h6) begin
                    compressed_out <= {sign, 1'b0, segment, abs_sample[11:9]};
                end
                else if (segment == 4'h7) begin
                    compressed_out <= {sign, 1'b0, segment, abs_sample[12:10]};
                end
                else begin
                    compressed_out <= {sign, 7'b0000000};
                end
                
                pcm_out <= {DATA_WIDTH{1'b0}};
                data_valid <= 1'b1;
            end
            else if (encode_mode == 1'b0) begin  // Decode mode
                sign = compressed_in[7];
                segment = compressed_in[6:4];
                
                // Reconstruct the sample based on segment
                if (segment == 4'h0) begin
                    abs_sample = {DATA_WIDTH{1'b0}};
                end
                else if (segment == 4'h1) begin
                    abs_sample = {1'b0, 1'b1, compressed_in[3:1], {(DATA_WIDTH-6){1'b0}}};
                end
                else if (segment == 4'h2) begin
                    abs_sample = {1'b0, 2'b10, compressed_in[3:1], {(DATA_WIDTH-7){1'b0}}};
                end
                else if (segment == 4'h3) begin
                    abs_sample = {1'b0, 3'b100, compressed_in[3:1], {(DATA_WIDTH-8){1'b0}}};
                end
                else if (segment == 4'h4) begin
                    abs_sample = {1'b0, 4'b1000, compressed_in[3:1], {(DATA_WIDTH-9){1'b0}}};
                end
                else if (segment == 4'h5) begin
                    abs_sample = {1'b0, 5'b10000, compressed_in[3:1], {(DATA_WIDTH-10){1'b0}}};
                end
                else if (segment == 4'h6) begin
                    abs_sample = {1'b0, 6'b100000, compressed_in[3:1], {(DATA_WIDTH-11){1'b0}}};
                end
                else if (segment == 4'h7) begin
                    abs_sample = {1'b0, 7'b1000000, compressed_in[3:1], {(DATA_WIDTH-12){1'b0}}};
                end
                else begin
                    abs_sample = {DATA_WIDTH{1'b0}};
                end
                
                // Apply sign bit
                if (sign) begin
                    pcm_out <= ~abs_sample + 1'b1;
                end else begin
                    pcm_out <= abs_sample;
                end
                
                compressed_out <= 8'h00;
                data_valid <= 1'b1;
            end
            else begin
                compressed_out <= 8'h00;
                pcm_out <= {DATA_WIDTH{1'b0}};
                data_valid <= 1'b0;
            end
        end
    end
endmodule