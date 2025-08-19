//SystemVerilog
module async_decoder_en(
    input [1:0] addr,
    input enable,
    output reg [3:0] decode_out
);
    always @(*) begin
        if (!enable) begin
            decode_out = 4'b0000;
        end else if (addr == 2'b00) begin
            decode_out = 4'b0001;
        end else if (addr == 2'b01) begin
            decode_out = 4'b0010;
        end else if (addr == 2'b10) begin
            decode_out = 4'b0100;
        end else if (addr == 2'b11) begin
            decode_out = 4'b1000;
        end else begin
            decode_out = 4'b0000;
        end
    end
endmodule