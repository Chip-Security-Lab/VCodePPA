//SystemVerilog
module gray_lut #(
    parameter DEPTH = 256, 
    parameter AW = 8
)(
    input wire clk,
    input wire rst_n,  // 添加复位信号
    input wire valid_in,  // 输入有效信号
    input wire [AW-1:0] addr,
    output wire [7:0] gray_out,
    output wire valid_out  // 输出有效信号
);
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 地址寄存器
    reg [AW-1:0] addr_stage1;
    
    // 流水线阶段1：地址寄存和有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= {AW{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
        end
    end
    
    // 内部连线
    wire [7:0] lut_data;
    reg [7:0] lut_data_stage2;
    
    // 存储器子模块实例化
    memory_block #(
        .DEPTH(DEPTH),
        .AW(AW),
        .DW(8)
    ) memory_inst (
        .clk(clk),
        .addr(addr_stage1),
        .data_out(lut_data)
    );
    
    // 流水线阶段2：存储器数据寄存和有效信号传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lut_data_stage2 <= 8'h0;
            valid_stage2 <= 1'b0;
        end else begin
            lut_data_stage2 <= lut_data;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出寄存器子模块实例化
    output_register output_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_stage2),
        .data_in(lut_data_stage2),
        .data_out(gray_out),
        .valid_in(valid_stage2),
        .valid_out(valid_out)
    );
    
endmodule

// 存储器子模块
module memory_block #(
    parameter DEPTH = 256,
    parameter AW = 8,
    parameter DW = 8
)(
    input wire clk,
    input wire [AW-1:0] addr,
    output wire [DW-1:0] data_out
);
    // 声明存储器
    reg [DW-1:0] mem [0:DEPTH-1];
    
    // 初始化存储器
    initial begin
        $readmemh("gray_table.hex", mem);
    end
    
    // 组合逻辑输出(不寄存，提高性能)
    assign data_out = mem[addr];
    
endmodule

// 输出寄存器子模块 - 增强版以支持流水线
module output_register (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire valid_in,
    input wire [7:0] data_in,
    output reg [7:0] data_out,
    output reg valid_out
);
    // 时序逻辑，当使能信号高时更新输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h0;
            valid_out <= 1'b0;
        end else if (en) begin
            data_out <= data_in;
            valid_out <= valid_in;
        end
    end
    
endmodule