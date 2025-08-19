//SystemVerilog
// 顶层模块
module async_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    input wire we
);

    // 实例化存储单元模块
    ram_cell #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_cell_inst (
        .addr(addr),
        .din(din),
        .dout(dout),
        .we(we)
    );

endmodule

// 存储单元模块
module ram_cell #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we
);

    // 存储阵列
    reg [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];
    
    // 先行借位减法器相关信号
    wire [DATA_WIDTH-1:0] borrow;
    wire [DATA_WIDTH-1:0] diff;
    
    // 生成先行借位
    assign borrow[0] = 1'b0;
    genvar i;
    generate
        for(i = 1; i < DATA_WIDTH; i = i + 1) begin : gen_borrow
            assign borrow[i] = (mem[addr][i-1] < din[i-1]) || 
                             ((mem[addr][i-1] == din[i-1]) && borrow[i-1]);
        end
    endgenerate
    
    // 计算差值
    genvar j;
    generate
        for(j = 0; j < DATA_WIDTH; j = j + 1) begin : gen_diff
            assign diff[j] = mem[addr][j] ^ din[j] ^ borrow[j];
        end
    endgenerate

    // 读写控制逻辑
    always @(addr or we or din) begin
        if (we) begin
            mem[addr] = din;
        end
        dout = mem[addr];
    end

endmodule