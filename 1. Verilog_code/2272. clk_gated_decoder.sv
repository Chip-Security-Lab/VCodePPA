module clk_gated_decoder(
    input clk,
    input [2:0] addr,
    input enable,
    output reg [7:0] select
);
    wire gated_clk;
    assign gated_clk = clk & enable;
    
    always @(posedge gated_clk) begin
        select <= (8'b00000001 << addr);
    end
endmodule