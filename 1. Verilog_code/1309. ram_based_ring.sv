module ram_based_ring #(parameter ADDR_WIDTH=4) (
    input clk, rst,
    output reg [2**ADDR_WIDTH-1:0] ram_out
);
reg [ADDR_WIDTH-1:0] addr;
always @(posedge clk) begin
    if (rst) begin
        addr <= 0;
        ram_out <= 1;
    end else begin
        addr <= addr + 1;
        ram_out <= {ram_out[0], ram_out[2**ADDR_WIDTH-1:1]};
    end
end
endmodule
