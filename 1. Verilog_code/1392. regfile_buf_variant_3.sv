//SystemVerilog
module regfile_buf #(parameter DW=32) (
    input clk,
    input rst_n,
    input [1:0] wr_sel, rd_sel,
    input wr_en,
    input data_valid_in,
    output reg data_valid_out,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    // 内部寄存器文件
    reg [DW-1:0] regs[0:3];
    
    // 流水线阶段1: 地址解码和读取
    reg [1:0] rd_sel_stage1;
    reg data_valid_stage1;
    reg [DW-1:0] read_data_stage1;
    
    // 流水线阶段2: 数据有效信号
    reg data_valid_stage2;
    
    // 写入操作处理 - 寄存器0
    always @(posedge clk) begin
        if (!rst_n) begin
            regs[0] <= {DW{1'b0}};
        end
        else if (wr_en && data_valid_in && (wr_sel == 2'b00)) begin
            regs[0] <= din;
        end
    end
    
    // 写入操作处理 - 寄存器1
    always @(posedge clk) begin
        if (!rst_n) begin
            regs[1] <= {DW{1'b0}};
        end
        else if (wr_en && data_valid_in && (wr_sel == 2'b01)) begin
            regs[1] <= din;
        end
    end
    
    // 写入操作处理 - 寄存器2
    always @(posedge clk) begin
        if (!rst_n) begin
            regs[2] <= {DW{1'b0}};
        end
        else if (wr_en && data_valid_in && (wr_sel == 2'b10)) begin
            regs[2] <= din;
        end
    end
    
    // 写入操作处理 - 寄存器3
    always @(posedge clk) begin
        if (!rst_n) begin
            regs[3] <= {DW{1'b0}};
        end
        else if (wr_en && data_valid_in && (wr_sel == 2'b11)) begin
            regs[3] <= din;
        end
    end
    
    // 流水线阶段1: 读地址寄存
    always @(posedge clk) begin
        if (!rst_n) begin
            rd_sel_stage1 <= 2'b0;
        end
        else begin
            rd_sel_stage1 <= rd_sel;
        end
    end
    
    // 流水线阶段1: 数据有效信号寄存
    always @(posedge clk) begin
        if (!rst_n) begin
            data_valid_stage1 <= 1'b0;
        end
        else begin
            data_valid_stage1 <= data_valid_in;
        end
    end
    
    // 流水线阶段1: 数据读取
    always @(posedge clk) begin
        if (!rst_n) begin
            read_data_stage1 <= {DW{1'b0}};
        end
        else begin
            read_data_stage1 <= regs[rd_sel];
        end
    end
    
    // 流水线阶段2: 数据输出
    always @(posedge clk) begin
        if (!rst_n) begin
            dout <= {DW{1'b0}};
        end
        else begin
            dout <= read_data_stage1;
        end
    end
    
    // 流水线阶段2: 数据有效信号传递
    always @(posedge clk) begin
        if (!rst_n) begin
            data_valid_stage2 <= 1'b0;
        end
        else begin
            data_valid_stage2 <= data_valid_stage1;
        end
    end
    
    // 流水线阶段2: 输出有效信号
    always @(posedge clk) begin
        if (!rst_n) begin
            data_valid_out <= 1'b0;
        end
        else begin
            data_valid_out <= data_valid_stage2;
        end
    end
    
endmodule