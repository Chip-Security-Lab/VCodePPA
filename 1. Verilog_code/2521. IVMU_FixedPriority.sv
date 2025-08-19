module IVMU_FixedPriority #(parameter WIDTH=8, ADDR=4) (
    input clk, rst_n,
    input [WIDTH-1:0] int_req,
    output reg [ADDR-1:0] vec_addr
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) vec_addr <= 0;
    else begin
        casex (int_req)
            8'b1???_????: vec_addr <= 4'h7;
            8'b01??_????: vec_addr <= 4'h6;
            8'b001?_????: vec_addr <= 4'h5;
            default:      vec_addr <= 0;
        endcase
    end
end
endmodule