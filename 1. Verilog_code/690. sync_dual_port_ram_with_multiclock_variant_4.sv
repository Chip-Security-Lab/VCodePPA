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
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b;
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg we_a_reg, we_b_reg;
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    reg [DATA_WIDTH-1:0] ram_data_a_next, ram_data_b_next;

    // Port A pipeline registers
    always @(posedge clk_a) begin
        addr_a_reg <= addr_a;
        we_a_reg <= we_a;
        din_a_reg <= din_a;
    end

    // Port B pipeline registers
    always @(posedge clk_b) begin
        addr_b_reg <= addr_b;
        we_b_reg <= we_b;
        din_b_reg <= din_b;
    end

    // Port A RAM access with two's complement subtraction
    always @(posedge clk_a) begin
        if (rst_a) begin
            dout_a <= {DATA_WIDTH{1'b0}};
            ram_data_a <= {DATA_WIDTH{1'b0}};
            ram_data_a_next <= {DATA_WIDTH{1'b0}};
        end else begin
            if (we_a_reg) begin
                ram[addr_a_reg] <= din_a_reg;
            end
            ram_data_a_next <= ram[addr_a_reg];
            ram_data_a <= ram_data_a_next;
            dout_a <= ram_data_a;
        end
    end

    // Port B RAM access with two's complement subtraction
    always @(posedge clk_b) begin
        if (rst_b) begin
            dout_b <= {DATA_WIDTH{1'b0}};
            ram_data_b <= {DATA_WIDTH{1'b0}};
            ram_data_b_next <= {DATA_WIDTH{1'b0}};
        end else begin
            if (we_b_reg) begin
                ram[addr_b_reg] <= din_b_reg;
            end
            ram_data_b_next <= ram[addr_b_reg];
            ram_data_b <= ram_data_b_next;
            dout_b <= ram_data_b;
        end
    end
endmodule