//SystemVerilog
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
    reg sample_mid_bit;
    reg transition_detected;
    
    // Sample counter for mid-bit detection
    always @(posedge clk) begin
        if (rst)
            sample_cnt <= 2'b00;
        else
            sample_cnt <= sample_cnt + 1'b1;
    end
    
    // Mid-bit detection logic
    always @(posedge clk) begin
        case (rst)
            1'b1: sample_mid_bit <= 1'b0;
            1'b0: sample_mid_bit <= (sample_cnt == 2'b01);
        endcase
    end
    
    // Manchester encoding logic
    always @(posedge clk) begin
        case ({rst, encode_en, sample_cnt[0]})
            3'b100, 3'b101, 3'b110, 3'b111: manchester_out <= 1'b0;
            3'b000, 3'b001, 3'b010: manchester_out <= manchester_out;
            3'b011: manchester_out <= data_in;
            3'b001: manchester_out <= ~data_in;
        endcase
    end
    
    // Transition detection for decoding
    always @(posedge clk) begin
        case ({rst, decode_en})
            2'b10, 2'b11: last_bit <= 1'b0;
            2'b01: last_bit <= manchester_in;
            2'b00: last_bit <= last_bit;
        endcase
    end
    
    // Transition evaluation logic
    always @(posedge clk) begin
        case ({rst, decode_en})
            2'b10, 2'b11: transition_detected <= 1'b0;
            2'b01: transition_detected <= manchester_in != last_bit;
            2'b00: transition_detected <= transition_detected;
        endcase
    end
    
    // Data output generation
    always @(posedge clk) begin
        case ({rst, decode_en, sample_mid_bit})
            3'b100, 3'b101, 3'b110, 3'b111: data_out <= 1'b0;
            3'b001: data_out <= transition_detected;
            3'b000, 3'b010, 3'b011: data_out <= data_out;
        endcase
    end
    
    // Data valid signal generation
    always @(posedge clk) begin
        case ({rst, decode_en, sample_mid_bit})
            3'b100, 3'b101, 3'b110, 3'b111: data_valid <= 1'b0;
            3'b000: data_valid <= 1'b0;
            3'b001, 3'b011: data_valid <= sample_mid_bit;
            3'b010: data_valid <= 1'b0;
        endcase
    end
    
endmodule