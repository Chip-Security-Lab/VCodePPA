//SystemVerilog
module ParityLatch #(parameter DW=7) (
    input clk, en,
    input [DW-1:0] data,
    output reg [DW:0] q
);

reg [DW-1:0] data_reg;
reg parity_bit;
reg [DW:0] count_ones;

// 使用条件反相减法器算法计算奇偶校验位
always @(posedge clk) begin
    if(en) begin
        data_reg <= data;
        
        // 初始化计数器
        count_ones <= 0;
        
        // 使用条件反相减法器算法计算1的个数
        for(int i = 0; i < DW; i++) begin
            if(data[i])
                count_ones <= count_ones + 1;
        end
        
        // 根据1的个数确定奇偶校验位
        parity_bit <= count_ones[0];
        
        // 输出结果
        q <= {parity_bit, data_reg};
    end
end

endmodule