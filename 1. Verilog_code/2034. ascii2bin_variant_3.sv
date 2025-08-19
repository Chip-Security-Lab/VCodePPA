//SystemVerilog
module ascii2bin (
    input  wire [7:0] ascii_in,
    output reg  [6:0] bin_out
);
    always @(*) begin
        if (|ascii_in) begin
            bin_out = ascii_in[6:0];
        end else begin
            bin_out = 7'b0;
        end
    end
endmodule