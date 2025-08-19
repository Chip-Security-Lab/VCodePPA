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
    wire mid_bit;
    wire bit_transition;
    
    // Optimize comparisons with direct assignments
    assign mid_bit = (sample_cnt == 2'b01);
    assign bit_transition = (manchester_in ^ last_bit);
    
    // Manchester encoding with case structure
    always @(posedge clk) begin
        case (rst)
            1'b1: manchester_out <= 1'b0;
            1'b0: begin
                case (encode_en)
                    1'b1: manchester_out <= sample_cnt[0] ? ~data_in : data_in;
                    1'b0: manchester_out <= manchester_out; // Maintain current value
                endcase
            end
        endcase
    end
    
    // Optimized sample counter with case structure
    always @(posedge clk) begin
        case (rst)
            1'b1: sample_cnt <= 2'b00;
            1'b0: sample_cnt <= sample_cnt + 1'b1;
        endcase
    end
    
    // Manchester decoding with case structure
    always @(posedge clk) begin
        case (rst)
            1'b1: begin
                last_bit <= 1'b0;
                data_out <= 1'b0;
                data_valid <= 1'b0;
            end
            1'b0: begin
                case (decode_en)
                    1'b1: begin
                        last_bit <= manchester_in;
                        case (mid_bit)
                            1'b1: begin
                                data_out <= bit_transition;
                                data_valid <= 1'b1;
                            end
                            1'b0: data_valid <= 1'b0;
                        endcase
                    end
                    1'b0: data_valid <= 1'b0;
                endcase
            end
        endcase
    end
endmodule