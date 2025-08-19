//SystemVerilog
module param_ring_counter #(
    parameter CNT_WIDTH = 8
)(
    input wire clk_in,
    input wire rst_in,
    output reg [CNT_WIDTH-1:0] counter_out
);
    // 优化的环形计数器实现
    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in)
            counter_out <= {{(CNT_WIDTH-1){1'b0}}, 1'b1};
        else
            counter_out <= {counter_out[CNT_WIDTH-2:0], counter_out[CNT_WIDTH-1]};
    end
endmodule