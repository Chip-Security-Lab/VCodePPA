module excess3_to_bcd (
    input wire [3:0] excess3_in,
    output reg [3:0] bcd_out,
    output reg valid_out
);
    always @(*) begin
        if (excess3_in >= 4'h3 && excess3_in <= 4'hC) begin
            bcd_out = excess3_in - 4'h3;
            valid_out = 1'b1;
        end else begin
            bcd_out = 4'h0;
            valid_out = 1'b0;
        end
    end
endmodule