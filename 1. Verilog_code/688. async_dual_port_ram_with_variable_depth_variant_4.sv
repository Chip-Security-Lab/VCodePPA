//SystemVerilog
// Memory core module with improved timing
module ram_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we
);

    reg [DATA_WIDTH-1:0] memory [0:RAM_DEPTH-1];
    reg [ADDR_WIDTH-1:0] addr_reg;
    
    always @(posedge clk) begin
        addr_reg <= addr;
        if (we) begin
            memory[addr] <= din;
        end
        dout <= memory[addr_reg];
    end

endmodule

// Port interface with address decoder
module port_interface #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire we,
    output reg [ADDR_WIDTH-1:0] core_addr,
    output reg [DATA_WIDTH-1:0] core_din,
    input wire [DATA_WIDTH-1:0] core_dout,
    output reg core_we
);

    always @(posedge clk) begin
        core_addr <= addr;
        core_din <= din;
        core_we <= we;
        dout <= core_dout;
    end

endmodule

// Memory controller with arbitration
module memory_controller #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    output reg [ADDR_WIDTH-1:0] core_addr,
    output reg [DATA_WIDTH-1:0] core_din,
    input wire [DATA_WIDTH-1:0] core_dout,
    output reg core_we
);

    reg port_sel;
    
    always @(posedge clk) begin
        port_sel <= ~port_sel;
        if (port_sel) begin
            core_addr <= addr_a;
            core_din <= din_a;
            core_we <= we_a;
            dout_a <= core_dout;
        end else begin
            core_addr <= addr_b;
            core_din <= din_b;
            core_we <= we_b;
            dout_b <= core_dout;
        end
    end

endmodule

// Top-level dual port RAM module
module async_dual_port_ram_with_variable_depth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b
);

    // Memory controller signals
    wire [ADDR_WIDTH-1:0] ctrl_addr;
    wire [DATA_WIDTH-1:0] ctrl_din;
    wire [DATA_WIDTH-1:0] ctrl_dout;
    wire ctrl_we;

    // Memory controller
    memory_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) controller (
        .clk(clk),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .din_a(din_a),
        .din_b(din_b),
        .dout_a(dout_a),
        .dout_b(dout_b),
        .we_a(we_a),
        .we_b(we_b),
        .core_addr(ctrl_addr),
        .core_din(ctrl_din),
        .core_dout(ctrl_dout),
        .core_we(ctrl_we)
    );

    // Memory core
    ram_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .RAM_DEPTH(RAM_DEPTH)
    ) memory_core (
        .clk(clk),
        .addr(ctrl_addr),
        .din(ctrl_din),
        .dout(ctrl_dout),
        .we(ctrl_we)
    );

endmodule