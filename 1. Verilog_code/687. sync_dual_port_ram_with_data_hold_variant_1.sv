//SystemVerilog
module sync_dual_port_ram_with_data_hold #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    wire addr_a_changed, addr_b_changed;
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] dout_a_reg, dout_b_reg;
    
    // 合并RAM和地址控制逻辑，减少模块间通信开销
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_reg <= 0;
            addr_b_reg <= 0;
            dout_a_reg <= 0;
            dout_b_reg <= 0;
        end else begin
            // 地址变化检测和寄存器更新
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            
            // 写操作和读操作合并，减少时钟周期
            if (we_a) ram[addr_a] <= din_a;
            if (we_b) ram[addr_b] <= din_b;
            
            // 使用寄存器输出，提高时序性能
            dout_a_reg <= ram[addr_a];
            dout_b_reg <= ram[addr_b];
        end
    end
    
    // 使用组合逻辑检测地址变化，减少寄存器使用
    assign addr_a_changed = |(addr_a ^ addr_a_reg);
    assign addr_b_changed = |(addr_b ^ addr_b_reg);
    
    // 直接输出寄存器值，提高时序性能
    assign dout_a = dout_a_reg;
    assign dout_b = dout_b_reg;
    
endmodule