//SystemVerilog
module sync_ram_with_error_detection #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    output reg error_flag
);

    // 流水线寄存器
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [DATA_WIDTH-1:0] din_stage1;
    reg we_stage1;
    
    reg [DATA_WIDTH-1:0] ram_data_stage2;
    reg [DATA_WIDTH-1:0] din_stage2;
    reg we_stage2;
    reg [ADDR_WIDTH-1:0] addr_stage2;
    
    reg [DATA_WIDTH-1:0] ram_data_stage3;
    reg [DATA_WIDTH-1:0] din_stage3;
    reg we_stage3;
    reg [ADDR_WIDTH-1:0] addr_stage3;

    // RAM存储器
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    // 流水线第1级: 地址和数据锁存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {addr_stage1, din_stage1, we_stage1} <= 0;
        end else begin
            {addr_stage1, din_stage1, we_stage1} <= {addr, din, we};
        end
    end

    // 流水线第2级: RAM读取
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {ram_data_stage2, din_stage2, we_stage2, addr_stage2} <= 0;
        end else begin
            ram_data_stage2 <= ram[addr_stage1];
            {din_stage2, we_stage2, addr_stage2} <= {din_stage1, we_stage1, addr_stage1};
        end
    end

    // 流水线第3级: 错误检测和写操作
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {ram_data_stage3, din_stage3, we_stage3, addr_stage3} <= 0;
        end else begin
            {ram_data_stage3, din_stage3, we_stage3, addr_stage3} <= 
                {ram_data_stage2, din_stage2, we_stage2, addr_stage2};
        end
    end

    // 流水线第4级: 输出和错误标志
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {dout, error_flag} <= 0;
        end else begin
            if (we_stage3) begin
                ram[addr_stage3] <= din_stage3;
                error_flag <= 0;
            end
            dout <= ram_data_stage3;
            error_flag <= error_flag | (ram_data_stage3 !== dout);
        end
    end

endmodule