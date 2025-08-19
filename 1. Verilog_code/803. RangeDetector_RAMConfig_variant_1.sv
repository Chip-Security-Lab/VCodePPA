//SystemVerilog
module RangeDetector_RAMConfig #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk,
    input rst_n,
    input valid_in,
    input wr_en,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [DATA_WIDTH-1:0] wr_data,
    input [DATA_WIDTH-1:0] data_in,
    output reg out_flag,
    output reg valid_out
);

// 使用双端口RAM替代单端口RAM,减少读写冲突
reg [DATA_WIDTH-1:0] threshold_ram [2**ADDR_WIDTH-1:0];
reg [DATA_WIDTH-1:0] low_reg, high_reg;

// 流水线阶段1：数据输入和阈值读取阶段
reg [DATA_WIDTH-1:0] data_stage1;
reg valid_stage1;

// 流水线阶段2：比较阶段
reg low_compare_stage2;
reg high_compare_stage2;
reg valid_stage2;

// 流水线阶段1: 寄存输入数据和更新RAM
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage1 <= {DATA_WIDTH{1'b0}};
        valid_stage1 <= 1'b0;
        low_reg <= {DATA_WIDTH{1'b0}};
        high_reg <= {DATA_WIDTH{1'b0}};
    end else begin
        // 输入数据寄存
        data_stage1 <= data_in;
        valid_stage1 <= valid_in;
        
        // RAM写入逻辑
        if (wr_en) begin
            threshold_ram[wr_addr] <= wr_data;
            if (wr_addr == 0) low_reg <= wr_data;
            if (wr_addr == 1) high_reg <= wr_data;
        end
    end
end

// 流水线阶段2: 进行比较操作
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        low_compare_stage2 <= 1'b0;
        high_compare_stage2 <= 1'b0;
        valid_stage2 <= 1'b0;
    end else begin
        low_compare_stage2 <= (data_stage1 >= low_reg);
        high_compare_stage2 <= (data_stage1 <= high_reg);
        valid_stage2 <= valid_stage1;
    end
end

// 流水线阶段3: 最终结果输出
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_flag <= 1'b0;
        valid_out <= 1'b0;
    end else begin
        out_flag <= low_compare_stage2 & high_compare_stage2;
        valid_out <= valid_stage2;
    end
end

endmodule