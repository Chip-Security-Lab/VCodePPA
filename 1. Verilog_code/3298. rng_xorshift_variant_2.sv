//SystemVerilog
module rng_xorshift_18_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                   axi_aclk,
    input                   axi_aresetn,
    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                   s_axi_awvalid,
    output reg              s_axi_awready,
    // AXI4-Lite Write Data Channel
    input  [7:0]            s_axi_wdata,
    input  [0:0]            s_axi_wstrb,
    input                   s_axi_wvalid,
    output reg              s_axi_wready,
    // AXI4-Lite Write Response Channel
    output reg  [1:0]       s_axi_bresp,
    output reg              s_axi_bvalid,
    input                   s_axi_bready,
    // AXI4-Lite Read Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_araddr,
    input                   s_axi_arvalid,
    output reg              s_axi_arready,
    // AXI4-Lite Read Data Channel
    output reg [7:0]        s_axi_rdata,
    output reg [1:0]        s_axi_rresp,
    output reg              s_axi_rvalid,
    input                   s_axi_rready
);

    // Internal registers
    reg [7:0] x_reg;
    reg [7:0] data_reg;
    reg       en_reg;

    // AXI4-Lite address decode
    localparam RNG_CTRL_ADDR = 4'h0;  // Write 1 to trigger next random, read returns last
    localparam RNG_DATA_ADDR = 4'h4;  // Read returns current random value

    // Xorshift combinational logic
    wire [7:0] x_lshift3;
    wire [7:0] x_rshift2;
    wire [7:0] x_lshift1;
    wire [7:0] x_xor_lshift3;
    wire [7:0] x_xor_lshift3_rshift2;
    wire [7:0] x_next;

    assign x_lshift3              = x_reg << 3;
    assign x_xor_lshift3          = x_reg ^ x_lshift3;
    assign x_rshift2              = x_xor_lshift3 >> 2;
    assign x_xor_lshift3_rshift2  = x_xor_lshift3 ^ x_rshift2;
    assign x_lshift1              = x_xor_lshift3_rshift2 << 1;
    assign x_next                 = x_xor_lshift3_rshift2 ^ x_lshift1;

    // Write address handshake
    always @(posedge axi_aclk) begin
        if (~axi_aresetn) begin
            s_axi_awready <= 1'b0;
        end else if (~s_axi_awready && s_axi_awvalid && ~s_axi_bvalid) begin
            s_axi_awready <= 1'b1;
        end else begin
            s_axi_awready <= 1'b0;
        end
    end

    // Write data handshake
    always @(posedge axi_aclk) begin
        if (~axi_aresetn) begin
            s_axi_wready <= 1'b0;
        end else if (~s_axi_wready && s_axi_wvalid && ~s_axi_bvalid) begin
            s_axi_wready <= 1'b1;
        end else begin
            s_axi_wready <= 1'b0;
        end
    end

    // Write logic
    always @(posedge axi_aclk) begin
        if (~axi_aresetn) begin
            en_reg   <= 1'b0;
        end else if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
            // Write operation
            if (s_axi_awaddr == RNG_CTRL_ADDR) begin
                if (s_axi_wdata[0]) begin
                    en_reg <= 1'b1; // trigger new random value
                end
            end
        end else begin
            en_reg <= 1'b0; // de-assert enable after one cycle
        end
    end

    // Write response logic
    always @(posedge axi_aclk) begin
        if (~axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= 2'b00; // OKAY
        end else if (s_axi_bvalid && s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
        end
    end

    // Read address handshake
    always @(posedge axi_aclk) begin
        if (~axi_aresetn) begin
            s_axi_arready <= 1'b0;
        end else if (~s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
            s_axi_arready <= 1'b1;
        end else begin
            s_axi_arready <= 1'b0;
        end
    end

    // Read data logic
    always @(posedge axi_aclk) begin
        if (~axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= 8'hAA;
        end else if (s_axi_arready && s_axi_arvalid) begin
            s_axi_rvalid <= 1'b1;
            s_axi_rresp  <= 2'b00; // OKAY
            if (s_axi_araddr == RNG_CTRL_ADDR) begin
                s_axi_rdata <= data_reg; // last random value
            end else if (s_axi_araddr == RNG_DATA_ADDR) begin
                s_axi_rdata <= x_reg; // current value
            end else begin
                s_axi_rdata <= 8'h00; // undefined address
            end
        end else if (s_axi_rvalid && s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
        end
    end

    // Random number core logic (clocked)
    always @(posedge axi_aclk) begin
        if (~axi_aresetn) begin
            x_reg    <= 8'hAA;
            data_reg <= 8'hAA;
        end else if (en_reg) begin
            x_reg    <= x_next;
            data_reg <= x_next;
        end else begin
            data_reg <= x_reg;
        end
    end

endmodule