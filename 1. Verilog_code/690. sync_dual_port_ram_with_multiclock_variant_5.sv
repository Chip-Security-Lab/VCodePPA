//SystemVerilog
module sync_dual_port_ram_with_multiclock #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk_a, clk_b,
    input wire rst_a, rst_b,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] ram_a_reg, ram_b_reg;

    // Port A
    always @(posedge clk_a) begin
        if (rst_a) begin
            dout_a <= {DATA_WIDTH{1'b0}};
            ram_a_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            ram_a_reg <= ram[addr_a];
            if (we_a) begin
                ram[addr_a] <= din_a;
                dout_a <= din_a;
            end else begin
                dout_a <= ram_a_reg;
            end
        end
    end

    // Port B
    always @(posedge clk_b) begin
        if (rst_b) begin
            dout_b <= {DATA_WIDTH{1'b0}};
            ram_b_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            ram_b_reg <= ram[addr_b];
            if (we_b) begin
                ram[addr_b] <= din_b;
                dout_b <= din_b;
            end else begin
                dout_b <= ram_b_reg;
            end
        end
    end
endmodule