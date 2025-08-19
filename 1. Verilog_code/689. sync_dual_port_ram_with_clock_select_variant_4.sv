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
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b;
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg we_a_reg, we_b_reg;
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    reg [DATA_WIDTH-1:0] ram_data_a_next, ram_data_b_next;

    // Port A pipeline registers with optimized timing
    always @(posedge clk_a) begin
        if (rst) begin
            addr_a_reg <= {ADDR_WIDTH{1'b0}};
            we_a_reg <= 1'b0;
            din_a_reg <= {DATA_WIDTH{1'b0}};
            ram_data_a <= {DATA_WIDTH{1'b0}};
        end else begin
            addr_a_reg <= addr_a;
            we_a_reg <= we_a;
            din_a_reg <= din_a;
            ram_data_a <= ram_data_a_next;
        end
    end

    // Port A read logic with optimized path
    always @(*) begin
        ram_data_a_next = ram[addr_a_reg];
    end

    // Port A write and read with optimized timing
    always @(posedge clk_a) begin
        if (rst) begin
            dout_a <= {DATA_WIDTH{1'b0}};
        end else begin
            if (we_a_reg) begin
                ram[addr_a_reg] <= din_a_reg;
            end
            dout_a <= ram_data_a;
        end
    end

    // Port B pipeline registers with optimized timing
    always @(posedge clk_b) begin
        if (rst) begin
            addr_b_reg <= {ADDR_WIDTH{1'b0}};
            we_b_reg <= 1'b0;
            din_b_reg <= {DATA_WIDTH{1'b0}};
            ram_data_b <= {DATA_WIDTH{1'b0}};
        end else begin
            addr_b_reg <= addr_b;
            we_b_reg <= we_b;
            din_b_reg <= din_b;
            ram_data_b <= ram_data_b_next;
        end
    end

    // Port B read logic with optimized path
    always @(*) begin
        ram_data_b_next = ram[addr_b_reg];
    end

    // Port B write and read with optimized timing
    always @(posedge clk_b) begin
        if (rst) begin
            dout_b <= {DATA_WIDTH{1'b0}};
        end else begin
            if (we_b_reg) begin
                ram[addr_b_reg] <= din_b_reg;
            end
            dout_b <= ram_data_b;
        end
    end
endmodule