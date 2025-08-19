module bcd2bin (
    input clk, enable,
    input [7:0] bcd_in,
    output reg [6:0] bin_out
);
    always @(posedge clk) begin
        if (enable) 
            bin_out <= (bcd_in[7:4]*10) + bcd_in[3:0];
    end
endmodule