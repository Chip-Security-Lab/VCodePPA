//SystemVerilog
module rng_toggle_9_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                  clk,
    input                  rst,

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

    // Internal registers
    reg [7:0] rand_val_reg_d, rand_val_reg_q;
    reg       rst_reg_d, rst_reg_q;

    // AXI4-Lite handshake signals
    reg s_axi_awready_d, s_axi_awready_q;
    reg s_axi_wready_d,  s_axi_wready_q;
    reg s_axi_bvalid_d,  s_axi_bvalid_q;
    reg s_axi_arready_d, s_axi_arready_q;
    reg s_axi_rvalid_d,  s_axi_rvalid_q;
    reg [7:0] s_axi_rdata_d, s_axi_rdata_q;

    // Address decoding
    localparam ADDR_RAND_VAL = 4'h0;
    localparam ADDR_RST      = 4'h4;

    // Write address/data handshake
    wire write_en = s_axi_awvalid && s_axi_wvalid && s_axi_awready && s_axi_wready;
    // Read address handshake
    wire read_en  = s_axi_arvalid && s_axi_arready;

    // Write response
    assign s_axi_bresp  = 2'b00;
    assign s_axi_bvalid = s_axi_bvalid_q;

    // Write address channel
    assign s_axi_awready = s_axi_awready_q;
    // Write data channel
    assign s_axi_wready  = s_axi_wready_q;

    // Read address channel
    assign s_axi_arready = s_axi_arready_q;
    // Read data channel
    assign s_axi_rdata   = s_axi_rdata_q;
    assign s_axi_rresp   = 2'b00;
    assign s_axi_rvalid  = s_axi_rvalid_q;

    // Combinational logic for forward retiming
    always @* begin
        // Default assignments
        s_axi_awready_d = s_axi_awready_q;
        s_axi_wready_d  = s_axi_wready_q;
        s_axi_bvalid_d  = s_axi_bvalid_q;
        s_axi_arready_d = s_axi_arready_q;
        s_axi_rvalid_d  = s_axi_rvalid_q;
        s_axi_rdata_d   = s_axi_rdata_q;
        rst_reg_d       = rst_reg_q;
        rand_val_reg_d  = rand_val_reg_q;

        // Write address handshake
        if (rst) begin
            s_axi_awready_d = 1'b1;
            s_axi_wready_d  = 1'b1;
            s_axi_bvalid_d  = 1'b0;
            rst_reg_d       = 1'b1;
        end else begin
            if (s_axi_awready_q && s_axi_awvalid) begin
                s_axi_awready_d = 1'b0;
            end else if (~s_axi_awready_q && s_axi_bready && s_axi_bvalid_q) begin
                s_axi_awready_d = 1'b1;
            end

            if (s_axi_wready_q && s_axi_wvalid) begin
                s_axi_wready_d = 1'b0;
            end else if (~s_axi_wready_q && s_axi_bready && s_axi_bvalid_q) begin
                s_axi_wready_d = 1'b1;
            end

            if (write_en) begin
                s_axi_bvalid_d = 1'b1;
            end else if (s_axi_bvalid_q && s_axi_bready) begin
                s_axi_bvalid_d = 1'b0;
            end

            // Register write logic
            if (write_en) begin
                case (s_axi_awaddr[3:0])
                    ADDR_RST: begin
                        if (s_axi_wstrb[0]) rst_reg_d = s_axi_wdata[0];
                    end
                    default: ;
                endcase
            end
        end

        // Read address handshake
        if (rst) begin
            s_axi_arready_d = 1'b1;
            s_axi_rvalid_d  = 1'b0;
            s_axi_rdata_d   = 8'h00;
        end else begin
            if (s_axi_arready_q && s_axi_arvalid) begin
                s_axi_arready_d = 1'b0;
                s_axi_rvalid_d  = 1'b1;
                case (s_axi_araddr[3:0])
                    ADDR_RAND_VAL: s_axi_rdata_d = rand_val_reg_q;
                    ADDR_RST:      s_axi_rdata_d = {7'b0, rst_reg_q};
                    default:       s_axi_rdata_d = 8'h00;
                endcase
            end else if (s_axi_rvalid_q && s_axi_rready) begin
                s_axi_arready_d = 1'b1;
                s_axi_rvalid_d  = 1'b0;
            end
        end

        // RNG logic with AXI4-Lite based reset
        if (rst || rst_reg_q) begin
            rand_val_reg_d = 8'h55;
        end else begin
            rand_val_reg_d = rand_val_reg_q ^ 8'b00000001;
        end
    end

    // Sequential logic
    always @(posedge clk) begin
        s_axi_awready_q <= s_axi_awready_d;
        s_axi_wready_q  <= s_axi_wready_d;
        s_axi_bvalid_q  <= s_axi_bvalid_d;
        s_axi_arready_q <= s_axi_arready_d;
        s_axi_rvalid_q  <= s_axi_rvalid_d;
        s_axi_rdata_q   <= s_axi_rdata_d;
        rst_reg_q       <= rst_reg_d;
        rand_val_reg_q  <= rand_val_reg_d;
    end

endmodule