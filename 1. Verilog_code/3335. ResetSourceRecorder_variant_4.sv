//SystemVerilog
module ResetSourceRecorder_AXI4Lite (
    input  wire         clk,
    input  wire         rst_n,

    // AXI4-Lite Write Address Channel
    input  wire [3:0]   s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg [1:0]    s_axi_bresp,
    output reg          s_axi_bvalid,
    input  wire         s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [3:0]   s_axi_araddr,
    input  wire         s_axi_arvalid,
    output reg          s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg [31:0]   s_axi_rdata,
    output reg [1:0]    s_axi_rresp,
    output reg          s_axi_rvalid,
    input  wire         s_axi_rready
);

    // Internal registers
    reg [1:0] last_reset_source;
    reg [1:0] reset_source_reg;

    // Internal signals for handshake
    wire write_addr_handshake;
    wire write_data_handshake;
    wire write_ready;
    wire read_addr_handshake;
    wire read_ready;

    // Address decode
    localparam ADDR_LAST_RESET_SOURCE = 4'h0;
    localparam ADDR_RESET_SOURCE      = 4'h4;

    // Handshake signals
    assign write_addr_handshake = (!s_axi_awready) && s_axi_awvalid;
    assign write_data_handshake = (!s_axi_wready) && s_axi_wvalid;
    assign write_ready = s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid;

    assign read_addr_handshake = (!s_axi_arready) && s_axi_arvalid;
    assign read_ready = s_axi_arready && s_axi_arvalid && (!s_axi_rvalid);

    // Write FSM
    reg is_write_addr_last_reset_source;
    reg is_write_addr_reset_source;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready      <= 1'b0;
            s_axi_wready       <= 1'b0;
            s_axi_bvalid       <= 1'b0;
            s_axi_bresp        <= 2'b00;
            last_reset_source  <= 2'b0;
            reset_source_reg   <= 2'b0;
        end else begin
            // Write address ready logic
            if (write_addr_handshake) begin
                s_axi_awready <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end

            // Write data ready logic
            if (write_data_handshake) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            // Prepare address decode for write
            if (write_ready) begin
                is_write_addr_last_reset_source <= (s_axi_awaddr[3:0] == ADDR_LAST_RESET_SOURCE);
                is_write_addr_reset_source      <= (s_axi_awaddr[3:0] == ADDR_RESET_SOURCE);
            end else begin
                is_write_addr_last_reset_source <= 1'b0;
                is_write_addr_reset_source      <= 1'b0;
            end

            // Write operation
            if (write_ready) begin
                if (s_axi_awaddr[3:0] == ADDR_LAST_RESET_SOURCE) begin
                    last_reset_source <= s_axi_wdata[1:0];
                end else if (s_axi_awaddr[3:0] == ADDR_RESET_SOURCE) begin
                    reset_source_reg <= s_axi_wdata[1:0];
                end
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Read FSM
    reg is_read_addr_last_reset_source;
    reg is_read_addr_reset_source;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'b0;
            s_axi_rresp   <= 2'b00;
        end else begin
            // Read address ready logic
            if (read_addr_handshake) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            // Prepare address decode for read
            if (read_ready) begin
                is_read_addr_last_reset_source <= (s_axi_araddr[3:0] == ADDR_LAST_RESET_SOURCE);
                is_read_addr_reset_source      <= (s_axi_araddr[3:0] == ADDR_RESET_SOURCE);
            end else begin
                is_read_addr_last_reset_source <= 1'b0;
                is_read_addr_reset_source      <= 1'b0;
            end

            // Read operation
            if (read_ready) begin
                if (s_axi_araddr[3:0] == ADDR_LAST_RESET_SOURCE) begin
                    s_axi_rdata <= {30'b0, last_reset_source};
                end else if (s_axi_araddr[3:0] == ADDR_RESET_SOURCE) begin
                    s_axi_rdata <= {30'b0, reset_source_reg};
                end else begin
                    s_axi_rdata <= 32'b0;
                end
                s_axi_rresp  <= 2'b00; // OKAY
                s_axi_rvalid <= 1'b1;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Reset behavior - update last_reset_source on reset deassertion
    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            last_reset_source <= reset_source_reg;
        end
    end

endmodule