module parity_buf #(parameter DW=9) (
    input clk, en,
    input [DW-2:0] data_in,
    output reg [DW-1:0] data_out
);
    always @(posedge clk) if(en) begin
        data_out <= {^data_in, data_in}; // 最高位存储校验位
    end
endmodule
