//SystemVerilog
module sr_latch_enable (
    input wire enable,
    input wire s,
    input wire r,
    output reg q
);
    wire [1:0] sr_ctrl;
    
    assign sr_ctrl = {s, r};
    
    always @(*) begin
        if (enable) begin
            if (sr_ctrl == 2'b10) begin
                q <= 1'b1;  // s=1, r=0
            end
            else if (sr_ctrl == 2'b01) begin
                q <= 1'b0;  // s=0, r=1
            end
            else begin
                q <= q;    // 保持当前状态
            end
        end
    end
endmodule