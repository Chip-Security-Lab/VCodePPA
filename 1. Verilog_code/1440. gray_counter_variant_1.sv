//SystemVerilog
module gray_counter #(parameter W=4) (
    input clk, rstn,
    output reg [W-1:0] gray
);
    reg [W-1:0] bin;
    
    always @(posedge clk) begin
        bin <= !rstn ? 'b0 : bin + 1'b1;
        gray <= !rstn ? 'b0 : (bin + 1'b1) ^ ((bin + 1'b1) >> 1);
    end
endmodule