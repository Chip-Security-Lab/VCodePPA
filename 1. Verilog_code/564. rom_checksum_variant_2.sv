//SystemVerilog
module rom_checksum #(
    parameter AW = 6
)(
    input logic         clk,      // 时钟信号
    input logic         rst_n,    // 复位信号
    input logic         req_valid, // 请求有效信号
    input logic [AW-1:0] addr,     // 地址输入
    output logic        resp_valid, // 响应有效信号
    output logic [8:0]  data      // 数据输出
);
    // 存储器定义
    logic [7:0] mem [0:(1<<AW)-1];
    
    // 流水线寄存器
    logic [AW-1:0] addr_r1;
    logic [AW-1:0] addr_r2; // 新增寄存器
    logic [7:0]    data_r1;
    logic [7:0]    data_r2; // 新增寄存器
    logic          valid_r1;
    logic          valid_r2; // 新增寄存器
    logic          parity_bit;
    
    // 初始化存储器内容
    initial begin
        for (int i = 0; i < (1<<AW); i++) begin
            mem[i] = i & 8'hFF;
        end
    end
    
    // 阶段1: 地址寄存与存储器读取
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_r1 <= {AW{1'b0}};
            valid_r1 <= 1'b0;
        end else begin
            addr_r1 <= addr;
            valid_r1 <= req_valid;
        end
    end
    
    // 新增阶段2: 地址寄存与数据读取
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_r2 <= {AW{1'b0}};
            valid_r2 <= 1'b0;
        end else begin
            addr_r2 <= addr_r1;
            valid_r2 <= valid_r1;
        end
    end
    
    // 阶段3: 数据读取与奇偶校验计算
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_r1 <= 8'h0;
            parity_bit <= 1'b0;
            resp_valid <= 1'b0;
        end else begin
            data_r1 <= mem[addr_r2];
            parity_bit <= ^mem[addr_r2];
            resp_valid <= valid_r2;
        end
    end
    
    // 阶段4: 数据输出组装
    assign data = {parity_bit, data_r1};
    
endmodule