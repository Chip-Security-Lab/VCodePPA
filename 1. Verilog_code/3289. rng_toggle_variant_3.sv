//SystemVerilog
module rng_toggle_9_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                   clk,
    input                   rst_n,
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

    // Address mapping
    localparam ADDR_RAND_VAL = 4'h0;

    // Internal registers
    reg [7:0] rand_val_q, rand_val_d;
    wire rst = ~rst_n;

    // AXI4-Lite handshake signals
    reg awready_q, awready_d;
    reg wready_q, wready_d;
    reg bvalid_q, bvalid_d;
    reg [1:0] bresp_q, bresp_d;
    reg arready_q, arready_d;
    reg rvalid_q, rvalid_d;
    reg [7:0] rdata_q, rdata_d;
    reg [1:0] rresp_q, rresp_d;

    assign s_axi_awready = awready_q;
    assign s_axi_wready  = wready_q;
    assign s_axi_bvalid  = bvalid_q;
    assign s_axi_bresp   = bresp_q;
    assign s_axi_arready = arready_q;
    assign s_axi_rvalid  = rvalid_q;
    assign s_axi_rdata   = rdata_q;
    assign s_axi_rresp   = rresp_q;

    // Pre-decode address for write/read
    wire is_awaddr_rand = (s_axi_awaddr[ADDR_WIDTH-1:0] == ADDR_RAND_VAL);
    wire is_araddr_rand = (s_axi_araddr[ADDR_WIDTH-1:0] == ADDR_RAND_VAL);

    // Write handshake detection
    wire write_handshake = s_axi_awvalid & awready_q & s_axi_wvalid & wready_q;
    wire write_done      = bvalid_q & s_axi_bready;

    // Read handshake detection
    wire read_handshake  = s_axi_arvalid & arready_q;
    wire read_done       = rvalid_q & s_axi_rready;

    // Write enables
    wire wr_en_rand      = write_handshake & is_awaddr_rand & s_axi_wstrb[0];

    // --- Path-Balanced Logic ---

    // Write address channel ready
    always @(*) begin
        awready_d = awready_q;
        if (rst)
            awready_d = 1'b1;
        else if (write_handshake)
            awready_d = 1'b0;
        else if (write_done)
            awready_d = 1'b1;
    end

    // Write data channel ready
    always @(*) begin
        wready_d = wready_q;
        if (rst)
            wready_d = 1'b1;
        else if (write_handshake)
            wready_d = 1'b0;
        else if (write_done)
            wready_d = 1'b1;
    end

    // Write response logic
    always @(*) begin
        bvalid_d = bvalid_q;
        bresp_d  = bresp_q;
        if (rst) begin
            bvalid_d = 1'b0;
            bresp_d  = 2'b00;
        end else if (write_handshake) begin
            bvalid_d = 1'b1;
            bresp_d  = 2'b00; // OKAY
        end else if (write_done) begin
            bvalid_d = 1'b0;
        end
    end

    // Write operation, path-balanced
    always @(*) begin
        rand_val_d = rand_val_q;
        if (rst) begin
            rand_val_d = 8'h55;
        end else if (wr_en_rand) begin
            rand_val_d = s_axi_wdata;
        end else if (write_handshake) begin
            rand_val_d = rand_val_q; // Hold
        end else begin
            rand_val_d = rand_val_q ^ 8'b00000001;
        end
    end

    // Read address channel ready
    always @(*) begin
        arready_d = arready_q;
        if (rst)
            arready_d = 1'b1;
        else if (read_handshake)
            arready_d = 1'b0;
        else if (read_done)
            arready_d = 1'b1;
    end

    // Read data channel, path-balanced
    always @(*) begin
        rvalid_d = rvalid_q;
        rresp_d  = rresp_q;
        rdata_d  = rdata_q;
        if (rst) begin
            rvalid_d = 1'b0;
            rresp_d  = 2'b00;
            rdata_d  = 8'h00;
        end else if (read_handshake) begin
            rvalid_d = 1'b1;
            rresp_d  = 2'b00; // OKAY
            rdata_d  = is_araddr_rand ? rand_val_q : 8'h00;
        end else if (read_done) begin
            rvalid_d = 1'b0;
        end
    end

    // Registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            awready_q <= 1'b1;
            wready_q  <= 1'b1;
            bvalid_q  <= 1'b0;
            bresp_q   <= 2'b00;
            rand_val_q<= 8'h55;
            arready_q <= 1'b1;
            rvalid_q  <= 1'b0;
            rdata_q   <= 8'h00;
            rresp_q   <= 2'b00;
        end else begin
            awready_q <= awready_d;
            wready_q  <= wready_d;
            bvalid_q  <= bvalid_d;
            bresp_q   <= bresp_d;
            rand_val_q<= rand_val_d;
            arready_q <= arready_d;
            rvalid_q  <= rvalid_d;
            rdata_q   <= rdata_d;
            rresp_q   <= rresp_d;
        end
    end

endmodule