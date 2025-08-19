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
    
    // Manchester encoding (data transition at mid-bit)
    always @(posedge clk) begin
        if (rst) manchester_out <= 1'b0;
        else if (encode_en)
            manchester_out <= sample_cnt[0] ? ~data_in : data_in;
    end
    
    // Sample counter for mid-bit detection
    always @(posedge clk) begin
        if (rst) sample_cnt <= 2'b00;
        else sample_cnt <= sample_cnt + 1'b1;
    end
    
    // Manchester decoding (detect transitions)
    always @(posedge clk) begin
        if (rst) begin
            last_bit <= 1'b0;
            data_out <= 1'b0;
            data_valid <= 1'b0;
        end else if (decode_en) begin
            last_bit <= manchester_in;
            if (sample_cnt == 2'b01) begin
                data_out <= manchester_in != last_bit ? 1'b1 : 1'b0;
                data_valid <= 1'b1;
            end else data_valid <= 1'b0;
        end
    end
endmodule