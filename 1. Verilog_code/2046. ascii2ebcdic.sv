module ascii2ebcdic (
    input wire clk, enable,
    input wire [7:0] ascii_in,
    output reg [7:0] ebcdic_out,
    output reg valid_out
);
    always @(posedge clk) begin
        if (enable) begin
            valid_out <= 1'b1;
            case (ascii_in)
                8'h30: ebcdic_out <= 8'hF0;  // 0
                8'h31: ebcdic_out <= 8'hF1;  // 1
                8'h41: ebcdic_out <= 8'hC1;  // A
                8'h42: ebcdic_out <= 8'hC2;  // B
                default: begin ebcdic_out <= 8'h00; valid_out <= 1'b0; end
            endcase
        end else valid_out <= 1'b0;
    end
endmodule