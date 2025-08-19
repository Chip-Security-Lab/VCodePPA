//SystemVerilog
module pipe_prefetch_buf #(parameter DW=32) (
    input logic clk,
    input logic rst_n,  // 添加复位信号
    input logic valid_in,  // 输入数据有效信号
    input logic ready_out, // 下游模块准备接收数据
    output logic ready_in, // 指示当前模块可以接收新数据
    output logic valid_out, // 输出数据有效信号
    input logic [DW-1:0] data_in,
    output logic [DW-1:0] data_out
);
    // 流水线数据寄存器
    logic [DW-1:0] stage0_data, stage1_data, stage2_data;
    
    // 流水线控制信号
    logic valid_stage0, valid_stage1, valid_stage2;
    logic stage0_ready, stage1_ready, stage2_ready;
    
    // 流水线状态控制 - 向后传播准备信号
    assign stage2_ready = ready_out || !valid_stage2;
    assign stage1_ready = stage2_ready || !valid_stage1;
    assign stage0_ready = stage1_ready || !valid_stage0;
    assign ready_in = stage0_ready;
    
    // 第一级流水线
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage0_data <= {DW{1'b0}};
            valid_stage0 <= 1'b0;
        end else if (ready_in && valid_in) begin
            stage0_data <= data_in;
            valid_stage0 <= 1'b1;
        end else if (stage0_ready && valid_stage0) begin
            valid_stage0 <= 1'b0;
        end
    end
    
    // 第二级流水线
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (stage1_ready && valid_stage0) begin
            stage1_data <= stage0_data;
            valid_stage1 <= 1'b1;
        end else if (stage1_ready && valid_stage1) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第三级流水线
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (stage2_ready && valid_stage1) begin
            stage2_data <= stage1_data;
            valid_stage2 <= 1'b1;
        end else if (stage2_ready && valid_stage2) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 输出连接
    assign data_out = stage2_data;
    assign valid_out = valid_stage2;
    
endmodule