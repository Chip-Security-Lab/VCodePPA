//SystemVerilog
module decoder_gated #(WIDTH=3) (
    input clk,
    input clk_en,
    input [WIDTH-1:0] addr,
    output reg [7:0] decoded
);

// Combinational logic
wire [7:0] decoded_next;
assign decoded_next = (1'b1 << addr);

// Sequential logic
always @(posedge clk) begin
    if (clk_en) begin
        decoded <= decoded_next;
    end
end

endmodule