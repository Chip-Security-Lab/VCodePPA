//SystemVerilog
//IEEE 1364-2005
module manchester_codec (
    input wire clk, rst, encode_en, decode_en,
    input wire data_in,
    input wire manchester_in,
    output reg manchester_out,
    output reg data_out,
    output reg data_valid
);
    reg last_bit;
    reg [1:0] sample_cnt;
    wire mid_bit;
    wire bit_transition;
    
    // Optimized sample counter for better timing
    always @(posedge clk) begin
        if (rst)
            sample_cnt <= 2'b00;
        else
            sample_cnt <= sample_cnt + 2'b01;
    end
    
    // Pre-compute signals for better logic distribution
    assign mid_bit = (sample_cnt == 2'b01);
    assign bit_transition = manchester_in ^ last_bit;
    
    // Optimized Manchester encoding with simplified logic
    always @(posedge clk) begin
        if (rst)
            manchester_out <= 1'b0;
        else if (encode_en)
            manchester_out <= sample_cnt[0] ? ~data_in : data_in;
    end
    
    // Optimized Manchester decoding with early computation
    always @(posedge clk) begin
        if (rst) begin
            last_bit <= 1'b0;
            data_out <= 1'b0;
            data_valid <= 1'b0;
        end 
        else if (decode_en) begin
            last_bit <= manchester_in;
            data_valid <= mid_bit;
            if (mid_bit)
                data_out <= bit_transition;
        end
        else begin
            data_valid <= 1'b0;
        end
    end
endmodule