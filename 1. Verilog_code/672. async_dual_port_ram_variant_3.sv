//SystemVerilog
// 顶层模块
module async_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b
);

    // 内部信号
    wire [DATA_WIDTH-1:0] ram_data_a, ram_data_b;
    wire [DATA_WIDTH-1:0] write_data_a, write_data_b;
    
    // 写控制模块实例化
    write_control #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) write_ctrl (
        .addr_a(addr_a),
        .addr_b(addr_b),
        .din_a(din_a),
        .din_b(din_b),
        .we_a(we_a),
        .we_b(we_b),
        .write_data_a(write_data_a),
        .write_data_b(write_data_b)
    );

    // 内存阵列模块实例化
    memory_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) mem_array (
        .addr_a(addr_a),
        .addr_b(addr_b),
        .write_data_a(write_data_a),
        .write_data_b(write_data_b),
        .we_a(we_a),
        .we_b(we_b),
        .ram_data_a(ram_data_a),
        .ram_data_b(ram_data_b)
    );

    // 读控制模块实例化
    read_control #(
        .DATA_WIDTH(DATA_WIDTH)
    ) read_ctrl (
        .ram_data_a(ram_data_a),
        .ram_data_b(ram_data_b),
        .dout_a(dout_a),
        .dout_b(dout_b)
    );

endmodule

// 写控制模块
module write_control #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    input wire we_a, we_b,
    output reg [DATA_WIDTH-1:0] write_data_a, write_data_b
);

    // 条件求和减法器实现
    wire [DATA_WIDTH-1:0] sub_a, sub_b;
    wire [DATA_WIDTH-1:0] sum_a, sum_b;
    wire [DATA_WIDTH-1:0] carry_a, carry_b;
    
    // 减法器A
    assign sub_a = ~din_a + 1'b1;  // 取反加1
    assign sum_a = sub_a + din_b;
    assign carry_a = (din_a[DATA_WIDTH-1] ^ din_b[DATA_WIDTH-1]) ? 
                    (sum_a[DATA_WIDTH-1] == din_b[DATA_WIDTH-1]) : 
                    (sum_a[DATA_WIDTH-1] == din_a[DATA_WIDTH-1]);
    
    // 减法器B
    assign sub_b = ~din_b + 1'b1;  // 取反加1
    assign sum_b = sub_b + din_a;
    assign carry_b = (din_b[DATA_WIDTH-1] ^ din_a[DATA_WIDTH-1]) ? 
                    (sum_b[DATA_WIDTH-1] == din_a[DATA_WIDTH-1]) : 
                    (sum_b[DATA_WIDTH-1] == din_b[DATA_WIDTH-1]);

    always @* begin
        write_data_a = (we_a) ? (carry_a ? sum_a : din_a) : {DATA_WIDTH{1'bz}};
        write_data_b = (we_b) ? (carry_b ? sum_b : din_b) : {DATA_WIDTH{1'bz}};
    end

endmodule

// 内存阵列模块
module memory_array #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] write_data_a, write_data_b,
    input wire we_a, we_b,
    output reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    always @* begin
        if (we_a) ram[addr_a] = write_data_a;
        if (we_b) ram[addr_b] = write_data_b;
        ram_data_a = ram[addr_a];
        ram_data_b = ram[addr_b];
    end

endmodule

// 读控制模块
module read_control #(
    parameter DATA_WIDTH = 8
)(
    input wire [DATA_WIDTH-1:0] ram_data_a, ram_data_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    always @* begin
        dout_a = ram_data_a;
        dout_b = ram_data_b;
    end

endmodule