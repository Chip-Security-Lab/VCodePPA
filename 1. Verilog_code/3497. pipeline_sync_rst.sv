module pipeline_sync_rst #(parameter WIDTH=8)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout_stage1, dout_stage2
);
always @(posedge clk) begin
    if (rst) begin
        dout_stage1 <= 0;
        dout_stage2 <= 0;
    end else begin
        dout_stage1 <= din;
        dout_stage2 <= dout_stage1;
    end
end
endmodule
