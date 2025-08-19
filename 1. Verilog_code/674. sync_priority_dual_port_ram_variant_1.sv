//SystemVerilog
module sync_priority_dual_port_ram #(
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

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
            ram_data_a <= 0;
            ram_data_b <= 0;
            addr_a_reg <= 0;
            addr_b_reg <= 0;
            we_a_reg <= 0;
            we_b_reg <= 0;
            read_first_reg <= 0;
        end else begin
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            we_a_reg <= we_a;
            we_b_reg <= we_b;
            read_first_reg <= read_first;

            if (read_first_reg) begin
                ram_data_a <= ram[addr_a_reg];
                ram_data_b <= ram[addr_b_reg];
                if (we_a_reg) ram[addr_a_reg] <= din_a;
                if (we_b_reg) ram[addr_b_reg] <= din_b;
            end else begin
                if (we_a_reg) ram[addr_a_reg] <= din_a;
                if (we_b_reg) ram[addr_b_reg] <= din_b;
                ram_data_a <= ram[addr_a_reg];
                ram_data_b <= ram[addr_b_reg];
            end

            dout_a <= ram_data_a;
            dout_b <= ram_data_b;
        end
    end
endmodule