//SystemVerilog
module sync_pos_edge_reg_pipelined (
    input  wire        clk,           // 时钟信号
    input  wire        rst_n,         // 低电平有效复位
    input  wire [7:0]  data_in,       // 输入数据
    input  wire        load_en,       // 加载使能
    input  wire        pipe_flush,    // 流水线刷新信号
    output reg  [7:0]  data_out,      // 输出数据
    output reg         data_valid     // 输出数据有效信号
);

    // 定义流水线阶段信号 - 数据路径
    reg [7:0] data_pipe1, data_pipe2;
    
    // 定义流水线阶段信号 - 控制路径
    reg       valid_pipe1, valid_pipe2;
    reg       load_en_pipe1, load_en_pipe2;
    
    // 流水线状态控制信号
    wire      pipe_reset = !rst_n || pipe_flush;
    
    //===================================================
    // 流水线第一级 - 输入数据采集
    //===================================================
    always @(posedge clk) begin
        if (pipe_reset) begin
            // 重置数据路径
            data_pipe1 <= 8'b0;
            // 重置控制路径
            valid_pipe1 <= 1'b0;
            load_en_pipe1 <= 1'b0;
        end
        else begin
            // 数据路径寄存
            data_pipe1 <= data_in;
            // 控制路径寄存
            valid_pipe1 <= 1'b1;
            load_en_pipe1 <= load_en;
        end
    end
    
    //===================================================
    // 流水线第二级 - 数据处理阶段
    //===================================================
    always @(posedge clk) begin
        if (pipe_reset) begin
            // 重置数据路径
            data_pipe2 <= 8'b0;
            // 重置控制路径
            valid_pipe2 <= 1'b0;
            load_en_pipe2 <= 1'b0;
        end
        else begin
            // 数据路径传递
            data_pipe2 <= data_pipe1;
            // 控制路径传递
            valid_pipe2 <= valid_pipe1;
            load_en_pipe2 <= load_en_pipe1;
        end
    end
    
    //===================================================
    // 流水线输出级 - 输出缓冲与控制
    //===================================================
    always @(posedge clk) begin
        if (pipe_reset) begin
            // 重置输出
            data_out <= 8'b0;
            data_valid <= 1'b0;
        end
        else begin
            // 数据输出逻辑
            if (load_en_pipe2 && valid_pipe2) begin
                data_out <= data_pipe2;
                data_valid <= 1'b1;
            end
            else begin
                // 保持数据，仅更新有效标志
                data_valid <= valid_pipe2;
            end
        end
    end

endmodule