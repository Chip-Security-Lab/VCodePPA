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
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg [ADDR_WIDTH-1:0] addr_a_reg2, addr_b_reg2;
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b;
    wire addr_a_changed, addr_b_changed;

    assign addr_a_changed = |(addr_a ^ addr_a_reg);
    assign addr_b_changed = |(addr_b ^ addr_b_reg);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= {DATA_WIDTH{1'b0}};
            dout_b <= {DATA_WIDTH{1'b0}};
            addr_a_reg <= {ADDR_WIDTH{1'b0}};
            addr_b_reg <= {ADDR_WIDTH{1'b0}};
            addr_a_reg2 <= {ADDR_WIDTH{1'b0}};
            addr_b_reg2 <= {ADDR_WIDTH{1'b0}};
            ram_data_a <= {DATA_WIDTH{1'b0}};
            ram_data_b <= {DATA_WIDTH{1'b0}};
        end else begin
            // 第一阶段：地址寄存和RAM读取
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            
            if (we_a) begin
                ram[addr_a] <= din_a;
                ram_data_a <= din_a;
            end else begin
                ram_data_a <= ram[addr_a];
            end

            if (we_b) begin
                ram[addr_b] <= din_b;
                ram_data_b <= din_b;
            end else begin
                ram_data_b <= ram[addr_b];
            end

            // 第二阶段：输出数据选择
            if (we_a) begin
                dout_a <= din_a;
            end else if (addr_a_changed) begin
                dout_a <= ram_data_a;
            end

            if (we_b) begin
                dout_b <= din_b;
            end else if (addr_b_changed) begin
                dout_b <= ram_data_b;
            end
        end
    end
endmodule