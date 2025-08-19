//SystemVerilog
// Top level module
module sync_dual_port_ram_with_clock_select #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk_a, clk_b,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b
);
    // Buffer registers for high fanout signals
    reg rst_buf_a, rst_buf_b;
    reg [DATA_WIDTH-1:0] din_a_buf, din_b_buf;
    reg [ADDR_WIDTH-1:0] addr_a_buf, addr_b_buf;
    
    // Buffering reset signal
    always @(posedge clk_a) begin
        rst_buf_a <= rst;
    end
    
    always @(posedge clk_b) begin
        rst_buf_b <= rst;
    end
    
    // Buffering data inputs
    always @(posedge clk_a) begin
        din_a_buf <= din_a;
        addr_a_buf <= addr_a;
    end
    
    always @(posedge clk_b) begin
        din_b_buf <= din_b;
        addr_b_buf <= addr_b;
    end

    // Port A instance
    ram_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) port_a (
        .clk(clk_a),
        .rst(rst_buf_a),
        .we(we_a),
        .addr(addr_a_buf),
        .din(din_a_buf),
        .dout(dout_a)
    );

    // Port B instance
    ram_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) port_b (
        .clk(clk_b),
        .rst(rst_buf_b),
        .we(we_b),
        .addr(addr_b_buf),
        .din(din_b_buf),
        .dout(dout_b)
    );

endmodule

// Memory core module with improved buffering
module ram_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Internal buffered signals to reduce fanout
    reg [DATA_WIDTH-1:0] din_internal;
    reg [ADDR_WIDTH-1:0] addr_internal;
    reg we_internal, rst_internal;
    
    // Buffer stage to reduce fanout
    always @(posedge clk) begin
        din_internal <= din;
        addr_internal <= addr;
        we_internal <= we;
        rst_internal <= rst;
    end

    always @(posedge clk) begin
        if (rst_internal) begin
            dout <= {DATA_WIDTH{1'b0}};
        end else begin
            if (we_internal) begin
                ram[addr_internal] <= din_internal;
            end
            dout <= ram[addr_internal];
        end
    end

endmodule