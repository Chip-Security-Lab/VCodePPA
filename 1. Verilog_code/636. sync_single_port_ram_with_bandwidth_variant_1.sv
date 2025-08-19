//SystemVerilog
module sync_single_port_ram_with_bandwidth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire bandwidth_control,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] next_dout;
    wire write_enable;
    wire read_enable;
    wire [DATA_WIDTH-1:0] ram_data;

    // 优化控制信号生成
    assign write_enable = bandwidth_control & we;
    assign read_enable = ~write_enable & bandwidth_control;
    
    // 预读取RAM数据
    assign ram_data = ram[addr];

    // 合并时序逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= {DATA_WIDTH{1'b0}};
        end else begin
            if (write_enable) begin
                ram[addr] <= din;
                dout <= din;
            end else if (read_enable) begin
                dout <= ram_data;
            end
        end
    end

endmodule