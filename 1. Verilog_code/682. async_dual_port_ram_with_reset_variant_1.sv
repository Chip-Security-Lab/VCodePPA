//SystemVerilog
// Top-level module
module async_dual_port_ram_with_reset #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire rst
);
    // Pipeline stage 1: Address and write data registration
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    reg we_a_reg, we_b_reg;
    
    // Pipeline stage 2: RAM output registration
    reg [DATA_WIDTH-1:0] ram_out_a_reg, ram_out_b_reg;
    
    // Pipeline stage 3: Reset control output registration
    reg [DATA_WIDTH-1:0] dout_a_reg, dout_b_reg;
    
    // RAM array instance
    ram_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_inst (
        .addr_a(addr_a_reg),
        .addr_b(addr_b_reg),
        .din_a(din_a_reg),
        .din_b(din_b_reg),
        .we_a(we_a_reg),
        .we_b(we_b_reg),
        .dout_a(ram_out_a_reg),
        .dout_b(ram_out_b_reg)
    );
    
    // Pipeline stage 1: Register inputs
    always @(posedge clk) begin
        addr_a_reg <= addr_a;
        addr_b_reg <= addr_b;
        din_a_reg <= din_a;
        din_b_reg <= din_b;
        we_a_reg <= we_a;
        we_b_reg <= we_b;
    end
    
    // Pipeline stage 3: Reset control and output registration
    always @(posedge clk) begin
        if (rst) begin
            dout_a_reg <= 0;
            dout_b_reg <= 0;
        end else begin
            dout_a_reg <= ram_out_a_reg;
            dout_b_reg <= ram_out_b_reg;
        end
    end
    
    assign dout_a = dout_a_reg;
    assign dout_b = dout_b_reg;
endmodule

// Memory array submodule
module ram_array #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    input wire we_a, we_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    always @* begin
        if (we_a) ram[addr_a] = din_a;
        if (we_b) ram[addr_b] = din_b;
        dout_a = ram[addr_a];
        dout_b = ram[addr_b];
    end
endmodule