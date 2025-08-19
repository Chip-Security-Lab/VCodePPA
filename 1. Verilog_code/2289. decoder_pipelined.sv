module decoder_pipelined (
    input clk,
    input [3:0] addr,
    output reg [15:0] decoded
);
    reg [3:0] addr_reg;
    always @(posedge clk) begin
        addr_reg <= addr;
        decoded <= 1'b1 << addr_reg;
    end
endmodule