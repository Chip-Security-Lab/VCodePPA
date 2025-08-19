//SystemVerilog
module regfile_buf #(parameter DW=32) (
    input wire clk,
    input wire rst_n,  // 添加复位信号
    input wire [1:0] wr_sel, rd_sel,
    input wire wr_en,
    input wire data_valid_in,  // 输入数据有效信号
    output wire ready_for_input,  // 流水线可接收新输入信号
    input wire [DW-1:0] din,
    output wire [DW-1:0] dout,
    output wire data_valid_out  // 输出数据有效信号
);
    // 寄存器组
    reg [DW-1:0] regs[0:3];
    
    // 流水线寄存器 - 第一级 (读取选择和数据有效信号)
    reg [1:0] rd_sel_stage1;
    reg data_valid_stage1;
    
    // 流水线寄存器 - 第二级 (读取数据和数据有效信号)
    reg [DW-1:0] dout_stage2;
    reg data_valid_stage2;
    
    // 写入逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regs[0] <= {DW{1'b0}};
            regs[1] <= {DW{1'b0}};
            regs[2] <= {DW{1'b0}};
            regs[3] <= {DW{1'b0}};
        end else if (wr_en) begin
            regs[wr_sel] <= din;
        end
    end
    
    // 流水线第一级 - 捕获读选择信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_sel_stage1 <= 2'b00;
            data_valid_stage1 <= 1'b0;
        end else begin
            rd_sel_stage1 <= rd_sel;
            data_valid_stage1 <= data_valid_in;
        end
    end
    
    // 流水线第二级 - 读取数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage2 <= {DW{1'b0}};
            data_valid_stage2 <= 1'b0;
        end else begin
            dout_stage2 <= regs[rd_sel_stage1];
            data_valid_stage2 <= data_valid_stage1;
        end
    end
    
    // 前递逻辑 - 处理读写同一地址的数据冒险
    reg [DW-1:0] forwarded_data;
    reg forward_needed;
    
    always @(*) begin
        forward_needed = wr_en && (rd_sel_stage1 == wr_sel) && data_valid_stage1;
        forwarded_data = forward_needed ? din : regs[rd_sel_stage1];
    end
    
    // 输出赋值
    assign dout = dout_stage2;
    assign data_valid_out = data_valid_stage2;
    assign ready_for_input = 1'b1;  // 简单流水线总是ready

endmodule