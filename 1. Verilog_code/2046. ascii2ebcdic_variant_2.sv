//SystemVerilog
module ascii2ebcdic (
    input wire clk,
    input wire enable,
    input wire [7:0] ascii_in,
    output reg [7:0] ebcdic_out,
    output reg valid_out
);
    wire ascii_is_digit = (ascii_in >= 8'h30) && (ascii_in <= 8'h31);
    wire ascii_is_alpha = (ascii_in >= 8'h41) && (ascii_in <= 8'h42);

    reg [7:0] ebcdic_next;
    reg       valid_next;

    always @* begin
        if (ascii_is_digit) begin
            ebcdic_next = {4'hF, ascii_in[3:0]}; // 0xF0, 0xF1
            valid_next  = 1'b1;
        end else if (ascii_is_alpha) begin
            ebcdic_next = {4'hC, ascii_in[3:0]}; // 0xC1, 0xC2
            valid_next  = 1'b1;
        end else begin
            ebcdic_next = 8'h00;
            valid_next  = 1'b0;
        end
    end

    always @(posedge clk) begin
        if (enable) begin
            ebcdic_out <= ebcdic_next;
            valid_out  <= valid_next;
        end else begin
            valid_out  <= 1'b0;
        end
    end
endmodule