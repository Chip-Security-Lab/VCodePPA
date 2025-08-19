//SystemVerilog
module sync_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);

    // 存储器控制模块
    ram_control #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_ram_control (
        .clk(clk),
        .rst(rst),
        .we(we),
        .addr(addr),
        .din(din),
        .dout(dout)
    );

endmodule

module ram_control #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    // 存储器数组
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // 操作状态编码
    localparam [1:0] RESET = 2'b00;
    localparam [1:0] WRITE = 2'b01;
    localparam [1:0] READ  = 2'b10;
    
    // 状态信号
    reg [1:0] ram_state;
    
    // 状态转换逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_state <= RESET;
        end else begin
            case (ram_state)
                RESET: ram_state <= we ? WRITE : READ;
                WRITE: ram_state <= we ? WRITE : READ;
                READ:  ram_state <= we ? WRITE : READ;
                default: ram_state <= READ;
            endcase
        end
    end
    
    // 数据操作逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else begin
            case (ram_state)
                RESET: dout <= 0;
                WRITE: begin
                    ram[addr] <= din;
                    dout <= din;  // 写时同时更新输出，减少延迟
                end
                READ: dout <= ram[addr];
                default: dout <= ram[addr];
            endcase
        end
    end

endmodule