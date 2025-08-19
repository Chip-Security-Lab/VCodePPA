//SystemVerilog
module dual_port_async_rst #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  addr_wr, 
    input  wire [ADDR_WIDTH-1:0]  addr_rd,
    input  wire [DATA_WIDTH-1:0]  din,
    output reg  [DATA_WIDTH-1:0]  dout
);

    // 内存声明
    reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];
    
    // 写入逻辑 - 仅在写入使能时进行写入操作
    always @(posedge clk) begin
        if (wr_en) begin
            mem[addr_wr] <= din;
        end
    end
    
    // 读取逻辑 - 分离的进程提高了性能和清晰度
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= {DATA_WIDTH{1'b0}};
        end else begin
            dout <= mem[addr_rd];
        end
    end

endmodule