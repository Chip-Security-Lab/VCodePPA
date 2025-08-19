//SystemVerilog
module rom_checksum #(
    parameter AW = 6
)(
    input wire clk,               // 新增时钟信号
    input wire rst_n,             // 新增复位信号
    input wire [AW-1:0] addr,     // 地址输入
    input wire read_en,           // 新增读取使能信号
    output reg [8:0] data,        // 修改为寄存器输出
    output reg valid              // 新增数据有效信号
);
    // 存储器声明
    reg [7:0] mem [0:(1<<AW)-1];
    
    // 流水线寄存器
    reg [AW-1:0] addr_reg;        // 地址寄存器
    reg read_en_reg;              // 使能寄存器
    reg [7:0] data_reg;           // 数据寄存器
    reg parity_reg;               // 奇偶校验寄存器
    
    // 初始化存储器内容
    integer i;
    initial begin
        for (i = 0; i < (1<<AW); i = i + 1) begin
            mem[i] = i & 8'hFF;
        end
    end
    
    // 流水线第一级：地址寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= {AW{1'b0}};
            read_en_reg <= 1'b0;
        end else begin
            addr_reg <= addr;
            read_en_reg <= read_en;
        end
    end
    
    // 流水线第二级：数据和奇偶校验计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'h0;
            parity_reg <= 1'b0;
            valid <= 1'b0;
        end else begin
            if (read_en_reg) begin
                data_reg <= mem[addr_reg];
                parity_reg <= ^mem[addr_reg];
                valid <= 1'b1;
            end else begin
                valid <= 1'b0;
            end
        end
    end
    
    // 流水线第三级：输出组装
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 9'h0;
        end else begin
            if (valid) begin
                data <= {parity_reg, data_reg};
            end
        end
    end
endmodule