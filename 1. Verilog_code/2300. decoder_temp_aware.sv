module decoder_temp_aware #(parameter THRESHOLD=85) (
    input clk,
    input [7:0] temp,
    input [3:0] addr,
    output reg [15:0] decoded
);
    always @(posedge clk) begin
        if (temp > THRESHOLD)
            decoded <= (1'b1 << addr) & 16'h00FF; // 高温限制输出
        else
            decoded <= 1'b1 << addr;
    end
endmodule