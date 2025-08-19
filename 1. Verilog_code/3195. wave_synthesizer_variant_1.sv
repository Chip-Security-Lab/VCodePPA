//SystemVerilog
module wave_synthesizer #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,          // 添加复位信号
    input wire enable,         // 添加使能信号
    output reg [DATA_WIDTH-1:0] wave,
    output reg valid_out       // 添加输出有效信号
);

// 流水线寄存器
reg [ADDR_WIDTH-1:0] addr_counter_stage1;
reg [DATA_WIDTH-1:0] wave_data_stage2;
reg valid_stage1, valid_stage2;

// 预定义正弦波查找表
reg [DATA_WIDTH-1:0] sine_rom [0:2**ADDR_WIDTH-1];
initial $readmemh("sine_table.hex", sine_rom);

// 第一级流水线: 地址计数和更新
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_counter_stage1 <= {ADDR_WIDTH{1'b0}};
        valid_stage1 <= 1'b0;
    end else if (enable) begin
        addr_counter_stage1 <= addr_counter_stage1 + 1'b1;
        valid_stage1 <= 1'b1;
    end else begin
        valid_stage1 <= 1'b0;
    end
end

// 第二级流水线: 从ROM读取数据
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wave_data_stage2 <= {DATA_WIDTH{1'b0}};
        valid_stage2 <= 1'b0;
    end else begin
        wave_data_stage2 <= sine_rom[addr_counter_stage1];
        valid_stage2 <= valid_stage1;
    end
end

// 输出级: 数据输出
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wave <= {DATA_WIDTH{1'b0}};
        valid_out <= 1'b0;
    end else begin
        wave <= wave_data_stage2;
        valid_out <= valid_stage2;
    end
end

endmodule