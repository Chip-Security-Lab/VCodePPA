module IVMU_ProgOffset #(parameter OFFSET_W=16) (
    input clk,
    input [OFFSET_W-1:0] base_addr,
    input [3:0] int_id,
    output reg [OFFSET_W-1:0] vec_addr
);
always @(posedge clk) begin
    vec_addr <= base_addr + (int_id << 2);
end
endmodule
