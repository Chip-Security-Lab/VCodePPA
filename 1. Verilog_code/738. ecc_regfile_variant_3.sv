//SystemVerilog
module ecc_regfile #(
    parameter DW = 32,
    parameter AW = 4
)(
    input clk,
    input rst,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output reg parity_err
);
    // 分离寄存器数据和校验位
    reg [DW-1:0] mem_data [0:(1<<AW)-1];
    reg [0:0] mem_parity [0:(1<<AW)-1];
    reg [DW-1:0] rd_data;
    reg [0:0] rd_parity;
    
    // 预计算输入数据的奇偶校验
    wire din_parity = ^din;
    
    // 寄存器存储逻辑
    always @(posedge clk) begin
        if (rst) begin
            integer i;
            for (i = 0; i < (1<<AW); i = i + 1) begin
                mem_data[i] <= {DW{1'b0}};
                mem_parity[i] <= 1'b0;
            end
            parity_err <= 1'b0;
        end else begin
            // 读取逻辑，总是执行
            rd_data <= mem_data[addr];
            rd_parity <= mem_parity[addr];
            
            // 写入逻辑，条件执行
            if (wr_en) begin
                mem_data[addr] <= din;
                mem_parity[addr] <= din_parity;
            end
        end
    end
    
    // 将校验错误检测放在单独的always块中，减少关键路径长度
    always @(posedge clk) begin
        if (rst) begin
            parity_err <= 1'b0;
        end else begin
            parity_err <= (^rd_data) ^ rd_parity;
        end
    end

    // 输出赋值
    assign dout = rd_data;
endmodule