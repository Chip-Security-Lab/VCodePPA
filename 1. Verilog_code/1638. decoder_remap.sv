module decoder_remap (
    input clk,
    input [7:0] base_addr,
    input [7:0] addr,
    output reg select
);
reg [7:0] mapped_addr;
always @(posedge clk) begin
    mapped_addr <= addr - base_addr;
    select <= (mapped_addr < 8'h10);
end
endmodule