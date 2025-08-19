//SystemVerilog
module sync_dual_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    reg we_a_reg, we_b_reg;
    reg en_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_reg <= 0;
            addr_b_reg <= 0;
            din_a_reg <= 0;
            din_b_reg <= 0;
            we_a_reg <= 0;
            we_b_reg <= 0;
            en_reg <= 0;
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            din_a_reg <= din_a;
            din_b_reg <= din_b;
            we_a_reg <= we_a;
            we_b_reg <= we_b;
            en_reg <= en;

            if (en_reg) begin
                if (we_a_reg) ram[addr_a_reg] <= din_a_reg;
                if (we_b_reg) ram[addr_b_reg] <= din_b_reg;
                dout_a <= ram[addr_a_reg];
                dout_b <= ram[addr_b_reg];
            end
        end
    end
endmodule