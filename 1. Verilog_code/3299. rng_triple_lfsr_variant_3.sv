//SystemVerilog
module rng_triple_lfsr_19_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                  clk,
    input                  rst_n,

    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                   s_axi_awvalid,
    output                  s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  [7:0]            s_axi_wdata,
    input  [0:0]            s_axi_wstrb,
    input                   s_axi_wvalid,
    output                  s_axi_wready,

    // AXI4-Lite Write Response Channel
    output [1:0]            s_axi_bresp,
    output                  s_axi_bvalid,
    input                   s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_araddr,
    input                   s_axi_arvalid,
    output                  s_axi_arready,

    // AXI4-Lite Read Data Channel
    output [7:0]            s_axi_rdata,
    output [1:0]            s_axi_rresp,
    output                  s_axi_rvalid,
    input                   s_axi_rready
);

    // AXI4-Lite address map
    localparam ADDR_RND = 4'h0;
    localparam ADDR_EN  = 4'h4;
    localparam ADDR_RST = 4'h8;

    // Internal registers for LFSR state and enable/rst
    reg [7:0] lfsr_a, lfsr_b, lfsr_c;
    reg [7:0] reg_rnd;
    reg       reg_en;
    reg       reg_rst;

    // Write state machine
    reg awready_reg, wready_reg, bvalid_reg;
    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [1:0] bresp_reg;

    // Read state machine
    reg arready_reg, rvalid_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg [7:0] rdata_reg;
    reg [1:0] rresp_reg;

    // AXI4-Lite handshake
    assign s_axi_awready = awready_reg;
    assign s_axi_wready  = wready_reg;
    assign s_axi_bvalid  = bvalid_reg;
    assign s_axi_bresp   = bresp_reg;

    assign s_axi_arready = arready_reg;
    assign s_axi_rvalid  = rvalid_reg;
    assign s_axi_rdata   = rdata_reg;
    assign s_axi_rresp   = rresp_reg;

    // Write address handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready_reg <= 1'b1;
            awaddr_reg  <= {ADDR_WIDTH{1'b0}};
        end else if (s_axi_awvalid && awready_reg) begin
            awready_reg <= 1'b0;
            awaddr_reg  <= s_axi_awaddr;
        end else if (bvalid_reg && s_axi_bready) begin
            awready_reg <= 1'b1;
        end
    end

    // Write data handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wready_reg <= 1'b1;
        end else if (s_axi_wvalid && wready_reg) begin
            wready_reg <= 1'b0;
        end else if (bvalid_reg && s_axi_bready) begin
            wready_reg <= 1'b1;
        end
    end

    // Write response
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;
        end else if ((~bvalid_reg) && (~awready_reg) && (~wready_reg)) begin
            bvalid_reg <= 1'b1;
            bresp_reg  <= 2'b00; // OKAY
        end else if (bvalid_reg && s_axi_bready) begin
            bvalid_reg <= 1'b0;
        end
    end

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_en  <= 1'b0;
            reg_rst <= 1'b0;
        end else if ((~awready_reg) && (~wready_reg) && s_axi_wvalid && s_axi_awvalid) begin
            case (awaddr_reg)
                ADDR_EN:  reg_en  <= s_axi_wdata[0];
                ADDR_RST: reg_rst <= s_axi_wdata[0];
                default: ;
            endcase
        end else begin
            reg_rst <= 1'b0; // auto-clear after use
        end
    end

    // Read address handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arready_reg <= 1'b1;
            araddr_reg  <= {ADDR_WIDTH{1'b0}};
        end else if (s_axi_arvalid && arready_reg) begin
            arready_reg <= 1'b0;
            araddr_reg  <= s_axi_araddr;
        end else if (rvalid_reg && s_axi_rready) begin
            arready_reg <= 1'b1;
        end
    end

    // Read data valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvalid_reg <= 1'b0;
            rdata_reg  <= 8'b0;
            rresp_reg  <= 2'b00;
        end else if ((~arready_reg) && (~rvalid_reg)) begin
            rvalid_reg <= 1'b1;
            case (araddr_reg)
                ADDR_RND: rdata_reg <= reg_rnd;
                ADDR_EN:  rdata_reg <= {7'b0, reg_en};
                ADDR_RST: rdata_reg <= {7'b0, reg_rst};
                default:  rdata_reg <= 8'b0;
            endcase
            rresp_reg <= 2'b00; // OKAY
        end else if (rvalid_reg && s_axi_rready) begin
            rvalid_reg <= 1'b0;
        end
    end

    // LFSR core logic
    wire feedback_a = lfsr_a[7] ^ lfsr_a[3];
    wire feedback_b = lfsr_b[7] ^ lfsr_b[2];
    wire feedback_c = lfsr_c[7] ^ lfsr_c[1];

    // Conditional sum subtractor for 8-bit: result = a - b
    function [7:0] conditional_sum_subtractor_8bit;
        input [7:0] operand_a;
        input [7:0] operand_b;
        reg [7:0] not_b;
        reg [7:0] sum0, sum1;
        reg carry0, carry1;
        reg [7:0] partial_sum;
        reg [7:0] carry;
        integer i;
    begin
        not_b = ~operand_b;
        // Sum with carry-in = 0
        sum0[0] = operand_a[0] ^ not_b[0] ^ 1'b0;
        carry[0] = (operand_a[0] & not_b[0]) | (operand_a[0] & 1'b0) | (not_b[0] & 1'b0);
        for (i=1; i<8; i=i+1) begin
            sum0[i] = operand_a[i] ^ not_b[i] ^ carry[i-1];
            carry[i] = (operand_a[i] & not_b[i]) | (operand_a[i] & carry[i-1]) | (not_b[i] & carry[i-1]);
        end
        conditional_sum_subtractor_8bit = sum0;
    end
    endfunction

    // Use conditional sum subtractor in the LFSR output calculation
    wire [7:0] lfsr_xor_ab;
    assign lfsr_xor_ab = lfsr_a ^ lfsr_b;

    wire [7:0] lfsr_rnd_sub;
    assign lfsr_rnd_sub = conditional_sum_subtractor_8bit(lfsr_xor_ab, lfsr_c);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_a  <= 8'hFE;
            lfsr_b  <= 8'hBD;
            lfsr_c  <= 8'h73;
            reg_rnd <= 8'b0;
        end else if (reg_rst) begin
            lfsr_a  <= 8'hFE;
            lfsr_b  <= 8'hBD;
            lfsr_c  <= 8'h73;
            reg_rnd <= 8'b0;
        end else if (reg_en) begin
            lfsr_a  <= {lfsr_a[6:0], feedback_a};
            lfsr_b  <= {lfsr_b[6:0], feedback_b};
            lfsr_c  <= {lfsr_c[6:0], feedback_c};
            reg_rnd <= lfsr_rnd_sub;
        end
    end

endmodule