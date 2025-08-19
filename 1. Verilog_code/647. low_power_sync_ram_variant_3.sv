//SystemVerilog
module low_power_sync_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire low_power_mode
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] next_dout;
    reg [DATA_WIDTH-1:0] ram_data;
    reg [DATA_WIDTH-1:0] write_data;
    reg write_enable;
    reg active_mode;

    // 预计算活动模式信号，减少关键路径上的条件判断
    always @(*) begin
        active_mode = !low_power_mode;
        write_enable = we & active_mode;
        write_data = din;
    end

    // 读数据路径 - 直接访问RAM
    always @(*) begin
        ram_data = ram[addr];
    end

    // 优化输出选择逻辑 - 减少条件嵌套
    always @(*) begin
        if (rst) begin
            next_dout = {DATA_WIDTH{1'b0}};
        end else if (active_mode) begin
            // 在活动模式下，根据写使能选择输出
            next_dout = write_enable ? write_data : ram_data;
        end else begin
            // 在低功耗模式下保持当前输出
            next_dout = dout;
        end
    end

    // 时序逻辑 - 写操作和输出更新
    always @(posedge clk) begin
        if (write_enable) begin
            ram[addr] <= write_data;
        end
        dout <= next_dout;
    end

endmodule