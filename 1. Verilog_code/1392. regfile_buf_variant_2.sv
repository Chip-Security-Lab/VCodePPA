//SystemVerilog
module regfile_buf #(parameter DW=32) (
    input clk,
    input rst_n,               // 复位信号
    input [1:0] wr_sel, rd_sel,
    input wr_en,
    input data_valid_in,       // 输入数据有效信号
    output reg data_valid_out, // 输出数据有效信号
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    // 寄存器组
    reg [DW-1:0] regs[0:3];
    
    // 流水线阶段1: 地址解码
    reg [1:0] rd_sel_stage1;
    reg data_valid_stage1;
    
    // 流水线阶段2: 读取寄存器数据
    reg [DW-1:0] read_data_stage2;
    reg [1:0] rd_sel_stage2;
    reg data_valid_stage2;
    reg wr_en_stage2;
    reg [1:0] wr_sel_stage2;
    reg [DW-1:0] din_stage2;
    
    // 流水线阶段3: 数据选择和前递处理
    reg [DW-1:0] read_data_stage3;
    reg data_valid_stage3;
    
    // 流水线阶段4: 数据处理
    reg [DW-1:0] read_data_stage4;
    reg data_valid_stage4;
    
    // 流水线阶段5: 输出准备
    reg [DW-1:0] read_data_stage5;
    reg data_valid_stage5;
    
    // 写入寄存器操作
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
    
    // 流水线阶段1: 地址解码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_sel_stage1 <= 2'b00;
            data_valid_stage1 <= 1'b0;
        end else begin
            rd_sel_stage1 <= rd_sel;
            data_valid_stage1 <= data_valid_in;
        end
    end
    
    // 流水线阶段2: 读取寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data_stage2 <= {DW{1'b0}};
            rd_sel_stage2 <= 2'b00;
            data_valid_stage2 <= 1'b0;
            wr_en_stage2 <= 1'b0;
            wr_sel_stage2 <= 2'b00;
            din_stage2 <= {DW{1'b0}};
        end else begin
            read_data_stage2 <= regs[rd_sel_stage1];
            rd_sel_stage2 <= rd_sel_stage1;
            data_valid_stage2 <= data_valid_stage1;
            wr_en_stage2 <= wr_en;
            wr_sel_stage2 <= wr_sel;
            din_stage2 <= din;
        end
    end
    
    // 流水线阶段3: 数据选择和前递处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data_stage3 <= {DW{1'b0}};
            data_valid_stage3 <= 1'b0;
        end else begin
            // 前递逻辑处理
            if (wr_en_stage2 && (rd_sel_stage2 == wr_sel_stage2)) begin
                read_data_stage3 <= din_stage2; // 前递
            end else begin
                read_data_stage3 <= read_data_stage2;
            end
            data_valid_stage3 <= data_valid_stage2;
        end
    end
    
    // 流水线阶段4: 数据处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data_stage4 <= {DW{1'b0}};
            data_valid_stage4 <= 1'b0;
        end else begin
            read_data_stage4 <= read_data_stage3;
            data_valid_stage4 <= data_valid_stage3;
        end
    end
    
    // 流水线阶段5: 输出准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data_stage5 <= {DW{1'b0}};
            data_valid_stage5 <= 1'b0;
        end else begin
            read_data_stage5 <= read_data_stage4;
            data_valid_stage5 <= data_valid_stage4;
        end
    end
    
    // 输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {DW{1'b0}};
            data_valid_out <= 1'b0;
        end else begin
            dout <= read_data_stage5;
            data_valid_out <= data_valid_stage5;
        end
    end
    
endmodule