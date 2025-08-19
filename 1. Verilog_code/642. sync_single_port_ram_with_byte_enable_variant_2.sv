//SystemVerilog
module sync_single_port_ram_with_byte_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire [DATA_WIDTH/8-1:0] byte_en,
    output reg [DATA_WIDTH-1:0] dout
);

    // 内部信号定义
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    wire [DATA_WIDTH-1:0] write_data;
    wire [DATA_WIDTH-1:0] read_data;
    wire [DATA_WIDTH-1:0] next_dout;

    // 组合逻辑模块 - 字节使能写入数据计算
    byte_enable_logic #(
        .DATA_WIDTH(DATA_WIDTH)
    ) byte_enable_inst (
        .ram_data(ram[addr]),
        .din(din),
        .byte_en(byte_en),
        .write_data(write_data)
    );

    // 组合逻辑 - 读取数据
    assign read_data = ram[addr];

    // 组合逻辑 - 输出数据选择
    assign next_dout = rst ? {DATA_WIDTH{1'b0}} :
                      we ? write_data :
                      read_data;

    // 时序逻辑 - 寄存器更新
    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= write_data;
        end
        dout <= next_dout;
    end

endmodule

// 字节使能逻辑模块
module byte_enable_logic #(
    parameter DATA_WIDTH = 8
)(
    input wire [DATA_WIDTH-1:0] ram_data,
    input wire [DATA_WIDTH-1:0] din,
    input wire [DATA_WIDTH/8-1:0] byte_en,
    output reg [DATA_WIDTH-1:0] write_data
);

    // 条件反相减法器实现
    reg [DATA_WIDTH-1:0] inverted_data;
    reg [DATA_WIDTH-1:0] result;
    reg carry;
    integer i, j;
    
    always @(*) begin
        write_data = ram_data;
        for (i = 0; i < DATA_WIDTH/8; i = i + 1) begin
            if (byte_en[i]) begin
                // 条件反相减法器算法
                inverted_data = ~din[i*8 +: 8];
                carry = 1'b1;
                
                for (j = 0; j < 8; j = j + 1) begin
                    result[j] = inverted_data[j] ^ carry;
                    carry = inverted_data[j] & carry;
                end
                
                write_data[i*8 +: 8] = result;
            end
        end
    end

endmodule