//SystemVerilog
module clk_gate_pipeline #(parameter STAGES=3) (
    input  wire clk,
    input  wire rst_n,  // 添加复位信号
    input  wire en,
    input  wire in,
    input  wire flush,  // 添加刷新信号
    output wire out,
    output wire valid_out  // 添加输出有效信号
);
    
    // 流水线数据寄存器
    reg [STAGES-1:0] pipe_data;
    // 流水线有效信号寄存器
    reg [STAGES-1:0] pipe_valid;
    
    // 输出连接
    assign out = pipe_data[STAGES-1];
    assign valid_out = pipe_valid[STAGES-1];
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            pipe_data <= {STAGES{1'b0}};
            pipe_valid <= {STAGES{1'b0}};
        end
        else if (flush) begin
            // 流水线刷新
            pipe_valid <= {STAGES{1'b0}};
            // 数据寄存器保持不变
        end
        else if (en) begin
            // 流水线移位逻辑
            pipe_data[0] <= in;
            pipe_valid[0] <= 1'b1;
            
            for (i = 1; i < STAGES; i = i + 1) begin
                pipe_data[i] <= pipe_data[i-1];
                pipe_valid[i] <= pipe_valid[i-1];
            end
        end
    end
    
endmodule