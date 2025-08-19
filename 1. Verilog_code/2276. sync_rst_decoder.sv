module sync_rst_decoder(
    input clk,
    input rst,
    input [3:0] addr,
    output reg [15:0] select
);
    always @(posedge clk) begin
        if (rst)
            select <= 16'b0;
        else
            select <= (16'b1 << addr);
    end
endmodule