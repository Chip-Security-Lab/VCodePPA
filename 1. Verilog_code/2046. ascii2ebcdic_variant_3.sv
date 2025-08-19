//SystemVerilog
module ascii2ebcdic (
    input wire clk,
    input wire enable,
    input wire [7:0] ascii_in,
    output reg [7:0] ebcdic_out,
    output reg valid_out
);
    always @(posedge clk) begin
        if (enable) begin
            if (ascii_in >= 8'h30 && ascii_in <= 8'h31) begin
                // Efficient mapping for '0' and '1'
                ebcdic_out <= 8'hF0 + (ascii_in - 8'h30);
                valid_out  <= 1'b1;
            end else if (ascii_in >= 8'h41 && ascii_in <= 8'h42) begin
                // Efficient mapping for 'A' and 'B'
                ebcdic_out <= 8'hC1 + (ascii_in - 8'h41);
                valid_out  <= 1'b1;
            end else begin
                ebcdic_out <= 8'h00;
                valid_out  <= 1'b0;
            end
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule