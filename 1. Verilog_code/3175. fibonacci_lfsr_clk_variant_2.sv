//SystemVerilog
module fibonacci_lfsr_clk(
    input clk,
    input rst,
    input ready,         // 新增：接收方准备接收信号
    output reg valid,    // 新增：数据有效信号
    output reg [3:0] data_out  // 输出LFSR生成的数据
);
    reg [4:0] lfsr;
    wire feedback = lfsr[4] ^ lfsr[2];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr <= 5'h1F;    // 非零初始值
            valid <= 1'b0;    // 复位时数据无效
            data_out <= 4'b0;
        end else begin
            if (ready || !valid) begin
                // 当接收方准备好接收或当前没有有效数据时
                lfsr <= {lfsr[3:0], feedback};
                data_out <= lfsr[3:0];  // 输出LFSR的低4位
                valid <= 1'b1;          // 新数据有效
            end
            // 当ready=0且valid=1时，保持当前状态直到接收方准备好
        end
    end
endmodule