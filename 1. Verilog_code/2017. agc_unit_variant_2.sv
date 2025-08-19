//SystemVerilog
module agc_unit #(parameter W=16) (
    input clk,
    input [W-1:0] in,
    output reg [W-1:0] out
);
    reg [W+1:0] peak_next;
    reg [W+1:0] peak_reg = 0;
    reg [W-1:0] in_reg;
    reg [W-1:0] agc_result;

    always @* begin
        if (in > peak_reg) begin
            peak_next = in;
        end else begin
            peak_next = peak_reg - (peak_reg >> 3);
        end
    end

    always @(posedge clk) begin
        peak_reg <= peak_next;
        in_reg <= in;
    end

    always @* begin
        if (peak_reg != 0) begin
            agc_result = (in_reg * 32767) / peak_reg;
        end else begin
            agc_result = (in_reg * 32767) / 1;
        end
    end

    always @(posedge clk) begin
        out <= agc_result;
    end
endmodule