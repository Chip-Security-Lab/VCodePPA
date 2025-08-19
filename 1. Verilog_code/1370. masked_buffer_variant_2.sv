//SystemVerilog
module masked_buffer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] data_in,
    input  wire [15:0] mask,
    input  wire        valid_in,
    output wire        ready_out,
    output reg  [15:0] data_out,
    output reg         valid_out,
    input  wire        ready_in
);
    // 内部信号
    reg [15:0] masked_data;
    reg [15:0] masked_prev;
    reg        valid_pipe;
    reg        stall;
    
    // 反压逻辑 - 当下游不准备好且当前有有效数据时
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stall <= 1'b0;
        else if (valid_out && !ready_in)
            stall <= 1'b1;
        else if (ready_in)
            stall <= 1'b0;
    end
    
    // 输入就绪信号 - 当处于流水线中或未被阻塞时
    assign ready_out = !stall;
    
    // 第一级流水线：计算掩码数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_data <= 16'h0;
            masked_prev <= 16'h0;
            valid_pipe <= 1'b0;
        end
        else if (ready_out && valid_in) begin
            masked_data <= data_in & mask;
            masked_prev <= data_out & ~mask;
            valid_pipe <= 1'b1;
        end
        else if (!stall) begin
            valid_pipe <= 1'b0;
        end
    end
    
    // 第二级流水线：合并数据并输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 16'h0;
            valid_out <= 1'b0;
        end
        else if (valid_pipe && !stall) begin
            data_out <= masked_data | masked_prev;
            valid_out <= 1'b1;
        end
        else if (ready_in) begin
            valid_out <= 1'b0;
        end
    end
endmodule