//SystemVerilog
module recursive_shifter #(parameter N=16) (
    input wire clk,                    // 添加时钟信号用于流水线
    input wire rst_n,                  // 添加复位信号
    input wire [N-1:0] data,
    input wire [$clog2(N)-1:0] shift,
    input wire valid_in,               // 输入有效信号
    output wire [N-1:0] result,
    output wire valid_out              // 输出有效信号
);
    localparam LOG2_N = $clog2(N);
    
    // 流水线寄存器和控制信号
    reg [N-1:0] data_pipe [0:LOG2_N-1];
    reg [$clog2(N)-1:0] shift_pipe [0:LOG2_N-1];
    reg [LOG2_N-1:0] valid_pipe;
    
    // 各移位阶段间的数据通路
    wire [N-1:0] shifted_data [0:LOG2_N-1];
    
    // 生成移位阶段逻辑
    genvar i;
    generate
        for (i = 0; i < LOG2_N; i = i + 1) begin: SHIFT_STAGE
            // 每个阶段的移位逻辑
            if (i == 0) begin: FIRST_STAGE
                // 第一阶段 - 移位1位
                assign shifted_data[i] = shift_pipe[i][0] ? 
                                        {data_pipe[i][N-2:0], data_pipe[i][N-1]} : 
                                        data_pipe[i];
            end
            else begin: OTHER_STAGES
                // 后续阶段 - 移位2^i位
                localparam SHIFT_AMT = 2**i;
                assign shifted_data[i] = shift_pipe[i][i] ? 
                                        {data_pipe[i][N-SHIFT_AMT-1:0], data_pipe[i][N-1:N-SHIFT_AMT]} : 
                                        data_pipe[i];
            end
        end
    endgenerate
    
    // 流水线寄存器更新逻辑
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有寄存器
            for (j = 0; j < LOG2_N; j = j + 1) begin
                data_pipe[j] <= {N{1'b0}};
                shift_pipe[j] <= {$clog2(N){1'b0}};
            end
            valid_pipe <= {LOG2_N{1'b0}};
        end else begin
            // 第一级流水线
            data_pipe[0] <= data;
            shift_pipe[0] <= shift;
            valid_pipe[0] <= valid_in;
            
            // 更新后续流水线阶段
            for (j = 1; j < LOG2_N; j = j + 1) begin
                data_pipe[j] <= shifted_data[j-1];
                shift_pipe[j] <= shift_pipe[j-1];
                valid_pipe[j] <= valid_pipe[j-1];
            end
        end
    end
    
    // 将最后一级移位结果连接到输出
    assign result = shifted_data[LOG2_N-1];
    assign valid_out = valid_pipe[LOG2_N-1];
    
endmodule