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
    reg we_a_reg, we_b_reg;
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;

    // Port A pipeline registers
    always @(posedge clk_a) begin
        we_a_reg <= we_a;
        addr_a_reg <= addr_a;
        din_a_reg <= din_a;
    end

    // Port B pipeline registers
    always @(posedge clk_b) begin
        we_b_reg <= we_b;
        addr_b_reg <= addr_b;
        din_b_reg <= din_b;
    end

    // Combined RAM access and output logic
    always @(posedge clk_a or posedge clk_b) begin
        if (rst) begin
            dout_a <= {DATA_WIDTH{1'b0}};
            dout_b <= {DATA_WIDTH{1'b0}};
        end else begin
            // Port A operations
            if (clk_a) begin
                if (!rst && we_a_reg) begin
                    ram[addr_a_reg] <= din_a_reg;
                    dout_a <= din_a_reg;
                end else if (!rst && !we_a_reg) begin
                    dout_a <= ram[addr_a_reg];
                end
            end

            // Port B operations
            if (clk_b) begin
                if (!rst && we_b_reg) begin
                    ram[addr_b_reg] <= din_b_reg;
                    dout_b <= din_b_reg;
                end else if (!rst && !we_b_reg) begin
                    dout_b <= ram[addr_b_reg];
                end
            end
        end
    end
endmodule