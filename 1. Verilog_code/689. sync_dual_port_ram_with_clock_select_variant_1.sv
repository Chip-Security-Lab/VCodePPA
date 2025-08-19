//SystemVerilog
module sync_dual_port_ram_with_clock_select #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk_a, clk_b,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] ram_a_reg, ram_b_reg;

    always @(posedge clk_a or posedge clk_b or posedge rst) begin
        if (rst) begin
            dout_a <= {DATA_WIDTH{1'b0}};
            dout_b <= {DATA_WIDTH{1'b0}};
            ram_a_reg <= {DATA_WIDTH{1'b0}};
            ram_b_reg <= {DATA_WIDTH{1'b0}};
        end else if (clk_a && we_a) begin
            ram[addr_a] <= din_a;
            ram_a_reg <= din_a;
            dout_a <= ram_a_reg;
        end else if (clk_a && !we_a) begin
            ram_a_reg <= ram[addr_a];
            dout_a <= ram_a_reg;
        end else if (clk_b && we_b) begin
            ram[addr_b] <= din_b;
            ram_b_reg <= din_b;
            dout_b <= ram_b_reg;
        end else if (clk_b && !we_b) begin
            ram_b_reg <= ram[addr_b];
            dout_b <= ram_b_reg;
        end
    end

endmodule