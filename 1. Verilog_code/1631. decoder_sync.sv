module decoder_sync #(ADDR_WIDTH=4, DATA_WIDTH=8) (
    input clk, rst_n,
    input [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) data <= 0;
    else case(addr[3:0])
        4'h0: data <= 8'h01;
        4'h4: data <= 8'h02;
        default: data <= 8'h00;
    endcase
end
endmodule