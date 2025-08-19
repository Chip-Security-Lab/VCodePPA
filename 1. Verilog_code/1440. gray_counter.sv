module gray_counter #(parameter W=4) (
    input clk, rstn,
    output reg [W-1:0] gray
);
reg [W-1:0] bin;
always @(posedge clk) begin
    if (!rstn) {bin,gray} <= 0;
    else begin
        bin <= bin + 1;
        gray <= (bin >> 1) ^ bin;
    end
end
endmodule