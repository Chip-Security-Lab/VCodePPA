module decoder_window #(AW=16) (
    input clk,
    input [AW-1:0] base_addr,
    input [AW-1:0] window_size,
    input [AW-1:0] addr_in,
    output reg valid
);
reg [AW-1:0] addr_reg;
always @(posedge clk) begin
    addr_reg <= addr_in;
    valid <= (addr_in >= base_addr) && 
            (addr_in < (base_addr + window_size));
end
endmodule