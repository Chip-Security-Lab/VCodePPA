//SystemVerilog
module sync_dual_port_ram_with_priority #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire read_first,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b;
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg we_a_reg, we_b_reg;
    reg read_first_reg;
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    
    // 优化：使用组合逻辑预计算地址冲突检测
    wire addr_collision;
    assign addr_collision = (addr_a_reg == addr_b_reg) && (we_a_reg || we_b_reg);
    
    // 优化：使用组合逻辑预计算优先级
    wire port_a_priority;
    assign port_a_priority = we_a_reg && !we_b_reg;
    
    // 第一级流水线：锁存输入信号
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_reg <= 0;
            addr_b_reg <= 0;
            we_a_reg <= 0;
            we_b_reg <= 0;
            read_first_reg <= 0;
            din_a_reg <= 0;
            din_b_reg <= 0;
        end else begin
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            we_a_reg <= we_a;
            we_b_reg <= we_b;
            read_first_reg <= read_first;
            din_a_reg <= din_a;
            din_b_reg <= din_b;
        end
    end

    // 第二级流水线：RAM读取
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data_a <= 0;
            ram_data_b <= 0;
        end else begin
            ram_data_a <= ram[addr_a_reg];
            ram_data_b <= ram[addr_b_reg];
        end
    end

    // 第三级流水线：写操作和输出选择
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            if (read_first_reg) begin
                dout_a <= ram_data_a;
                dout_b <= ram_data_b;
                
                // 优化：使用优先级逻辑处理写操作
                if (addr_collision) begin
                    if (port_a_priority) begin
                        ram[addr_a_reg] <= din_a_reg;
                    end else if (we_b_reg) begin
                        ram[addr_b_reg] <= din_b_reg;
                    end
                end else begin
                    if (we_a_reg) ram[addr_a_reg] <= din_a_reg;
                    if (we_b_reg) ram[addr_b_reg] <= din_b_reg;
                end
            end else begin
                // 优化：使用优先级逻辑处理写操作
                if (addr_collision) begin
                    if (port_a_priority) begin
                        ram[addr_a_reg] <= din_a_reg;
                    end else if (we_b_reg) begin
                        ram[addr_b_reg] <= din_b_reg;
                    end
                end else begin
                    if (we_a_reg) ram[addr_a_reg] <= din_a_reg;
                    if (we_b_reg) ram[addr_b_reg] <= din_b_reg;
                end
                
                dout_a <= ram_data_a;
                dout_b <= ram_data_b;
            end
        end
    end
endmodule