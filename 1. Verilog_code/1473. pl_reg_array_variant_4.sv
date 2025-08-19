//SystemVerilog
module pl_reg_array #(parameter DW=8, AW=4) (
    input clk,
    input rst_n,    // 添加复位信号
    input valid_in, // 输入有效信号
    output ready_in, // 输入就绪信号
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out,
    output valid_out // 输出有效信号
);

// 内存阵列
reg [DW-1:0] mem [0:(1<<AW)-1];

// 流水线阶段1：地址解码和写操作
reg [AW-1:0] addr_stage1;
reg [DW-1:0] data_in_stage1;
reg we_stage1;
reg valid_stage1;

// 额外的前递逻辑流水线寄存器
reg need_forwarding_stage1;
reg [AW-1:0] addr_for_forward_check;

// 流水线阶段2：读取和输出阶段
reg [DW-1:0] data_out_stage2;
reg valid_stage2;

// 流水线控制
assign ready_in = 1'b1; // 简单流水线始终准备好接收新数据

// 阶段1：地址寄存和写入
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage1 <= {AW{1'b0}};
        data_in_stage1 <= {DW{1'b0}};
        we_stage1 <= 1'b0;
        valid_stage1 <= 1'b0;
        addr_for_forward_check <= {AW{1'b0}};
    end else begin
        addr_stage1 <= addr;
        data_in_stage1 <= data_in;
        we_stage1 <= we;
        valid_stage1 <= valid_in;
        addr_for_forward_check <= addr;
        
        // 写入操作在阶段1
        if (we) begin
            mem[addr] <= data_in;
        end
    end
end

// 前递检测阶段 - 拆分组合逻辑路径
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        need_forwarding_stage1 <= 1'b0;
    end else begin
        need_forwarding_stage1 <= (we_stage1 && (addr_stage1 == addr_for_forward_check));
    end
end

// 阶段2：读取和输出
reg [DW-1:0] mem_read_data; // 添加中间寄存器来存储从内存读取的数据

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mem_read_data <= {DW{1'b0}};
        data_out_stage2 <= {DW{1'b0}};
        valid_stage2 <= 1'b0;
    end else begin
        // 读取操作，将读取与前递逻辑选择拆分
        mem_read_data <= mem[addr_stage1];
        
        // 前递选择逻辑 - 现在变成了寄存器到寄存器的操作
        data_out_stage2 <= need_forwarding_stage1 ? data_in_stage1 : mem_read_data;
        valid_stage2 <= valid_stage1;
    end
end

// 输出赋值
assign data_out = data_out_stage2;
assign valid_out = valid_stage2;

endmodule