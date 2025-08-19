//SystemVerilog
module async_right_shifter (
    input wire clk,          // 添加时钟输入
    input wire rst_n,        // 添加复位信号
    input wire data_in,
    input wire [3:0] control,
    output reg data_out
);
    // 分段流水线寄存器
    reg [4:0] stage_regs;
    
    // 流水线控制信号
    reg [3:0] control_pipe;
    
    // 优化的数据流管理
    wire [4:0] shift_path;
    
    // 捕获输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_regs[4] <= 1'b0;
            control_pipe <= 4'b0;
        end else begin
            stage_regs[4] <= data_in;
            control_pipe <= control;
        end
    end
    
    // 构建移位数据路径
    assign shift_path[4] = stage_regs[4];
    assign shift_path[3] = control_pipe[3] ? shift_path[4] : 1'b0;
    assign shift_path[2] = control_pipe[2] ? shift_path[3] : 1'b0;  
    assign shift_path[1] = control_pipe[1] ? shift_path[2] : 1'b0;
    assign shift_path[0] = control_pipe[0] ? shift_path[1] : 1'b0;
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
        end else begin
            data_out <= shift_path[0];
        end
    end
endmodule