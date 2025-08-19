//SystemVerilog
module rng_lfsr_12_axi4lite #(
    parameter ADDR_WIDTH = 4,  // 16 bytes address space
    parameter DATA_WIDTH = 32  // AXI4-Lite standard data width
)(
    input                   clk,
    input                   rst_n,

    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                   s_axi_awvalid,
    output                  s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  [DATA_WIDTH-1:0] s_axi_wdata,
    input  [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
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
    output [DATA_WIDTH-1:0] s_axi_rdata,
    output [1:0]            s_axi_rresp,
    output                  s_axi_rvalid,
    input                   s_axi_rready
);

    // Internal registers
    reg  [3:0] lfsr_state;
    wire       lfsr_fb;
    reg        lfsr_enable;
    
    // AXI4-Lite handshake registers
    reg        awready_reg, wready_reg, bvalid_reg, arready_reg, rvalid_reg;
    reg [1:0]  bresp_reg, rresp_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;

    // Address decode
    localparam ADDR_LFSR_CTRL  = 4'h0; // write: bit0 = enable
    localparam ADDR_LFSR_RAND  = 4'h4; // read:  [3:0] = rand_out

    // LFSR logic
    assign lfsr_fb = lfsr_state[3] ^ lfsr_state[2];

    // Write Address & Data handshake LUT
    wire write_handshake;
    assign write_handshake = s_axi_awvalid & s_axi_wvalid & ~bvalid_reg & ~awready_reg & ~wready_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready_reg <= 1'b0;
            wready_reg  <= 1'b0;
        end else begin
            awready_reg <= write_handshake;
            wready_reg  <= write_handshake;
        end
    end
    assign s_axi_awready = awready_reg;
    assign s_axi_wready  = wready_reg;

    // LUT for write enable
    wire write_enable;
    assign write_enable = s_axi_awvalid & s_axi_awready & s_axi_wvalid & s_axi_wready;

    // Address decode LUT for write
    reg addr_is_ctrl;
    always @(*) begin
        addr_is_ctrl = (s_axi_awaddr[ADDR_WIDTH-1:0] == ADDR_LFSR_CTRL);
    end

    // Write operation with LUT
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_enable <= 1'b0;
        end else if (write_enable && addr_is_ctrl && s_axi_wstrb[0]) begin
            lfsr_enable <= s_axi_wdata[0];
        end
    end

    // LFSR state update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_state <= 4'b1010;
        end else if (lfsr_enable) begin
            lfsr_state <= {lfsr_state[2:0], lfsr_fb};
        end
    end

    // Write Response Channel LUT
    wire bvalid_next;
    assign bvalid_next = awready_reg & wready_reg & ~bvalid_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;
        end else if (bvalid_next) begin
            bvalid_reg <= 1'b1;
            bresp_reg  <= 2'b00;
        end else if (bvalid_reg & s_axi_bready) begin
            bvalid_reg <= 1'b0;
        end
    end
    assign s_axi_bvalid = bvalid_reg;
    assign s_axi_bresp  = bresp_reg;

    // Read Address handshake LUT
    wire read_handshake;
    assign read_handshake = s_axi_arvalid & ~arready_reg & ~rvalid_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arready_reg <= 1'b0;
        end else begin
            arready_reg <= read_handshake;
        end
    end
    assign s_axi_arready = arready_reg;

    // LUT for read enable
    wire read_enable;
    assign read_enable = arready_reg & s_axi_arvalid & ~rvalid_reg;

    // LUT for read address decoding
    reg [DATA_WIDTH-1:0] lfsr_rand_lut [0:1];
    always @(*) begin
        lfsr_rand_lut[0] = {{(DATA_WIDTH-4){1'b0}}, lfsr_state};
        lfsr_rand_lut[1] = {{(DATA_WIDTH-1){1'b0}}, lfsr_enable};
    end

    wire [1:0] addr_decode;
    assign addr_decode = (s_axi_araddr[ADDR_WIDTH-1:0] == ADDR_LFSR_RAND) ? 2'b01 :
                         (s_axi_araddr[ADDR_WIDTH-1:0] == ADDR_LFSR_CTRL) ? 2'b10 : 2'b00;

    reg [DATA_WIDTH-1:0] lut_read_data;
    always @(*) begin
        case (addr_decode)
            2'b01: lut_read_data = lfsr_rand_lut[0]; // RAND
            2'b10: lut_read_data = lfsr_rand_lut[1]; // CTRL
            default: lut_read_data = {DATA_WIDTH{1'b0}};
        endcase
    end

    // Read Data Channel LUT
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvalid_reg <= 1'b0;
            rresp_reg  <= 2'b00;
            rdata_reg  <= {DATA_WIDTH{1'b0}};
        end else if (read_enable) begin
            rvalid_reg <= 1'b1;
            rresp_reg  <= 2'b00;
            rdata_reg  <= lut_read_data;
        end else if (rvalid_reg & s_axi_rready) begin
            rvalid_reg <= 1'b0;
        end
    end
    assign s_axi_rvalid = rvalid_reg;
    assign s_axi_rresp  = rresp_reg;
    assign s_axi_rdata  = rdata_reg;

endmodule