//SystemVerilog
// 顶层模块 - USB双端口缓冲区
module usb_dual_port_buffer #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6
)(
    // Port A - USB Interface
    input wire clk_a,
    input wire en_a,
    input wire we_a,
    input wire [ADDR_WIDTH-1:0] addr_a,
    input wire [DATA_WIDTH-1:0] data_a_in,
    output wire [DATA_WIDTH-1:0] data_a_out,
    // Port B - System Interface
    input wire clk_b,
    input wire en_b,
    input wire we_b,
    input wire [ADDR_WIDTH-1:0] addr_b,
    input wire [DATA_WIDTH-1:0] data_b_in,
    output wire [DATA_WIDTH-1:0] data_b_out
);
    // 共享内存资源
    wire [DATA_WIDTH-1:0] ram_data_a_read;
    wire [DATA_WIDTH-1:0] ram_data_b_read;
    wire ram_wr_a;
    wire ram_wr_b;
    
    // 实例化USB端口控制器 (Port A)
    usb_port_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) port_a_ctrl (
        .clk(clk_a),
        .en(en_a),
        .we(we_a),
        .addr(addr_a),
        .data_in(data_a_in),
        .data_out(data_a_out),
        .ram_data_read(ram_data_a_read),
        .ram_wr(ram_wr_a)
    );
    
    // 实例化系统端口控制器 (Port B)
    usb_port_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) port_b_ctrl (
        .clk(clk_b),
        .en(en_b),
        .we(we_b),
        .addr(addr_b),
        .data_in(data_b_in),
        .data_out(data_b_out),
        .ram_data_read(ram_data_b_read),
        .ram_wr(ram_wr_b)
    );
    
    // 实例化双端口RAM存储
    dual_port_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) memory (
        .clk_a(clk_a),
        .en_a(en_a),
        .we_a(ram_wr_a),
        .addr_a(addr_a),
        .data_a_in(data_a_in),
        .data_a_out(ram_data_a_read),
        .clk_b(clk_b),
        .en_b(en_b),
        .we_b(ram_wr_b),
        .addr_b(addr_b),
        .data_b_in(data_b_in),
        .data_b_out(ram_data_b_read)
    );
    
endmodule

// 端口控制器子模块 - 处理单个端口的读写操作
module usb_port_controller #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6
)(
    input wire clk,
    input wire en,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    input wire [DATA_WIDTH-1:0] ram_data_read,
    output wire ram_wr
);
    // 生成RAM写控制信号
    assign ram_wr = en && we;
    
    // 读操作处理
    always @(posedge clk) begin
        if (en) begin
            data_out <= ram_data_read;
        end
    end
endmodule

// 双端口内存子模块 - 存储数据的实际RAM
module dual_port_memory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6
)(
    // Port A
    input wire clk_a,
    input wire en_a,
    input wire we_a,
    input wire [ADDR_WIDTH-1:0] addr_a,
    input wire [DATA_WIDTH-1:0] data_a_in,
    output wire [DATA_WIDTH-1:0] data_a_out,
    // Port B
    input wire clk_b,
    input wire en_b,
    input wire we_b,
    input wire [ADDR_WIDTH-1:0] addr_b,
    input wire [DATA_WIDTH-1:0] data_b_in,
    output wire [DATA_WIDTH-1:0] data_b_out
);
    // 内存阵列
    reg [DATA_WIDTH-1:0] ram [(1<<ADDR_WIDTH)-1:0];
    
    // 读操作输出
    assign data_a_out = ram[addr_a];
    assign data_b_out = ram[addr_b];
    
    // Port A写操作 - 优化为时序逻辑
    always @(posedge clk_a) begin
        if (en_a && we_a) begin
            ram[addr_a] <= data_a_in;
        end
    end
    
    // Port B写操作 - 优化为时序逻辑
    always @(posedge clk_b) begin
        if (en_b && we_b) begin
            ram[addr_b] <= data_b_in;
        end
    end
endmodule