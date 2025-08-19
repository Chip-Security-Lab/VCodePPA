//SystemVerilog
module recursive_shifter #(parameter N=16) (
    input wire [N-1:0] data,
    input wire [$clog2(N)-1:0] shift,
    input wire clk, // 添加时钟输入以支持流水线
    input wire rst_n, // 添加复位信号
    output reg [N-1:0] result
);
    localparam LOG2_N = $clog2(N);
    
    // 流水线寄存器
    reg [N-1:0] pipe_data[0:LOG2_N];
    reg [$clog2(N)-1:0] pipe_shift[0:LOG2_N];
    
    // 中间数据路径信号
    wire [N-1:0] stage_out[0:LOG2_N];
    
    // 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_data[0] <= 0;
            pipe_shift[0] <= 0;
        end else begin
            pipe_data[0] <= data;
            pipe_shift[0] <= shift;
        end
    end
    
    // 生成流水线化的递归移位器
    genvar i;
    generate
        for (i = 0; i < LOG2_N; i = i + 1) begin : shift_stage
            // 当前级的移位操作
            localparam SHIFT_AMOUNT = (1 << i);
            
            // 移位逻辑 - 分割到独立的组合逻辑块
            assign stage_out[i] = pipe_shift[i][i] ? 
                {pipe_data[i][N-SHIFT_AMOUNT-1:0], pipe_data[i][N-1:N-SHIFT_AMOUNT]} :
                pipe_data[i];
            
            // 流水线寄存器
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pipe_data[i+1] <= 0;
                    pipe_shift[i+1] <= 0;
                end else begin
                    pipe_data[i+1] <= stage_out[i];
                    pipe_shift[i+1] <= pipe_shift[i];
                end
            end
        end
    endgenerate
    
    // 输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 0;
        end else begin
            result <= pipe_data[LOG2_N];
        end
    end
endmodule