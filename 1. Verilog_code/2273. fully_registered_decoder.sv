module fully_registered_decoder(
    input clk,
    input rst,
    input [2:0] addr_in,
    output reg [7:0] decode_out
);
    reg [2:0] addr_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            addr_reg <= 3'b000;
            decode_out <= 8'b00000000;
        end else begin
            addr_reg <= addr_in;
            decode_out <= (8'b00000001 << addr_reg);
        end
    end
endmodule