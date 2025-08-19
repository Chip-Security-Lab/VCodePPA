//SystemVerilog
module rle_codec (
    input wire clk, 
    input wire [7:0] data_in,
    output reg [7:0] data_out
);
    reg [7:0] count;
    
    always @(posedge clk) begin
        // 优化比较逻辑，减少比较器链
        if (data_in[7]) begin
            // 控制字节处理 - 直接使用位选择提取计数值
            count <= {1'b0, data_in[6:0]};
            data_out <= 8'h00;
        end else begin
            // 数据字节处理 - 使用减法+符号优化，减少比较步骤
            count <= |count ? count - 8'h01 : count;
            data_out <= data_in;
        end
    end
endmodule