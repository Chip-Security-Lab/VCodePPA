//SystemVerilog
module parity_check_recovery (
    input  wire        clk,
    input  wire        reset,
    input  wire [7:0]  data_in,
    input  wire        parity_in,
    output reg  [7:0]  data_out,
    output reg         valid,
    output reg         error
);
    // 寄存器化输入
    reg [7:0] data_in_reg;
    reg       parity_in_reg;
    
    // 计算奇偶校验
    wire calculated_parity;
    assign calculated_parity = ^data_in_reg;
    
    // 输入寄存器阶段 - 专门处理输入数据寄存
    always @(posedge clk) begin
        if (reset) begin
            data_in_reg   <= 8'h00;
            parity_in_reg <= 1'b0;
        end else begin
            data_in_reg   <= data_in;
            parity_in_reg <= parity_in;
        end
    end
    
    // 校验结果处理阶段 - 专门处理有效性信号
    always @(posedge clk) begin
        if (reset) begin
            valid <= 1'b0;
        end else begin
            valid <= 1'b1;
        end
    end
    
    // 奇偶校验错误检测阶段 - 专门处理错误标志
    always @(posedge clk) begin
        if (reset) begin
            error <= 1'b0;
        end else begin
            error <= (parity_in_reg != calculated_parity);
        end
    end
    
    // 数据输出处理阶段 - 专门处理数据输出逻辑
    always @(posedge clk) begin
        if (reset) begin
            data_out <= 8'h00;
        end else if (parity_in_reg == calculated_parity) begin
            data_out <= data_in_reg;
        end
        // 保持上一个有效数据，不需要显式赋值
    end
endmodule