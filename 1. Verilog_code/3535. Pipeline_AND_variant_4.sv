//SystemVerilog
module Pipeline_AND(
    input clk,
    input reset,
    input [15:0] din_a, din_b,
    input valid_in,
    output ready_out,
    output reg [15:0] dout,
    output reg valid_out,
    input ready_in
);
    
    // 内部寄存器 - 减少信号数量
    reg [15:0] din_a_reg, din_b_reg;
    reg processing;
    
    // 简化控制逻辑
    wire new_data = valid_in && ready_out;
    wire complete_transfer = valid_out && ready_in;
    
    // 简化输出就绪信号逻辑
    assign ready_out = !processing || complete_transfer;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // 合并复位逻辑
            {din_a_reg, din_b_reg, processing, dout, valid_out} <= {48'b0, 1'b0, 16'b0, 1'b0};
        end else begin
            // 使用并行处理逻辑优化性能
            if (new_data) begin
                din_a_reg <= din_a;
                din_b_reg <= din_b;
                processing <= 1'b1;
            end
            
            // 优化状态转换逻辑
            if (processing && !valid_out) begin
                dout <= din_a_reg & din_b_reg;
                valid_out <= 1'b1;
            end
            
            // 简化完成传输逻辑
            if (complete_transfer) begin
                valid_out <= 1'b0;
                if (!new_data) begin
                    processing <= 1'b0;
                end
            end
        end
    end
endmodule