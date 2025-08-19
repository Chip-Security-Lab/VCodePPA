//SystemVerilog
// SystemVerilog

// Top-level module: AXI4-Lite enabled reset synchronizer with hierarchical structure
module enabled_reset_sync_axi4lite (
    input  wire         clk,
    input  wire         rst_n,

    // AXI4-Lite Write Address Channel
    input  wire [3:0]   s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,

    // AXI4-Lite Write Response Channel
    output wire [1:0]   s_axi_bresp,
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [3:0]   s_axi_araddr,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,

    // AXI4-Lite Read Data Channel
    output wire [31:0]  s_axi_rdata,
    output wire [1:0]   s_axi_rresp,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready
);

    // Internal registers
    wire        enable_reg;
    wire        rst_out_n_reg;

    // Write and read channel internal signals
    wire        wr_enable_reg;
    wire        wr_enable_value;

    wire        rd_enable_reg;
    wire        rd_rst_out_n_reg;
    wire [31:0] rd_rdata_mux;
    wire [1:0]  rd_rresp_mux;

    // AXI4-Lite Write Channel Handler
    axi4lite_write_channel #(
        .ADDR_ENABLE     (4'h0)
    ) u_axi4lite_write_channel (
        .clk             (clk),
        .rst_n           (rst_n),
        .s_axi_awaddr    (s_axi_awaddr),
        .s_axi_awvalid   (s_axi_awvalid),
        .s_axi_awready   (s_axi_awready),
        .s_axi_wdata     (s_axi_wdata),
        .s_axi_wstrb     (s_axi_wstrb),
        .s_axi_wvalid    (s_axi_wvalid),
        .s_axi_wready    (s_axi_wready),
        .s_axi_bresp     (s_axi_bresp),
        .s_axi_bvalid    (s_axi_bvalid),
        .s_axi_bready    (s_axi_bready),
        .wr_enable_reg   (wr_enable_reg),
        .wr_enable_value (wr_enable_value)
    );

    // AXI4-Lite Read Channel Handler
    axi4lite_read_channel #(
        .ADDR_ENABLE     (4'h0),
        .ADDR_RST_OUT_N  (4'h4)
    ) u_axi4lite_read_channel (
        .clk             (clk),
        .rst_n           (rst_n),
        .s_axi_araddr    (s_axi_araddr),
        .s_axi_arvalid   (s_axi_arvalid),
        .s_axi_arready   (s_axi_arready),
        .s_axi_rdata     (s_axi_rdata),
        .s_axi_rresp     (s_axi_rresp),
        .s_axi_rvalid    (s_axi_rvalid),
        .s_axi_rready    (s_axi_rready),
        .enable_reg      (enable_reg),
        .rst_out_n_reg   (rst_out_n_reg)
    );

    // Enable register and synchronizer control
    enable_reset_register u_enable_reset_register (
        .clk             (clk),
        .rst_n           (rst_n),
        .wr_enable_reg   (wr_enable_reg),
        .wr_enable_value (wr_enable_value),
        .enable_reg      (enable_reg)
    );

    // Enabled reset synchronizer
    enabled_reset_synchronizer u_enabled_reset_synchronizer (
        .clk             (clk),
        .rst_n           (rst_n),
        .enable_reg      (enable_reg),
        .rst_out_n_reg   (rst_out_n_reg)
    );

endmodule

// -----------------------------------------------------------------------------
// Write Channel Handler: Handles AXI4-Lite write transactions and register write
// -----------------------------------------------------------------------------
module axi4lite_write_channel #(
    parameter ADDR_ENABLE = 4'h0
) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [3:0]   s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,
    output reg [1:0]    s_axi_bresp,
    output reg          s_axi_bvalid,
    input  wire         s_axi_bready,
    output reg          wr_enable_reg,
    output reg          wr_enable_value
);

    typedef enum reg [1:0] {WRITE_IDLE, WRITE_RESP} write_state_t;
    write_state_t write_state;

    localparam RESP_OKAY = 2'b00;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_state      <= WRITE_IDLE;
            s_axi_awready    <= 1'b0;
            s_axi_wready     <= 1'b0;
            s_axi_bvalid     <= 1'b0;
            s_axi_bresp      <= RESP_OKAY;
            wr_enable_reg    <= 1'b0;
            wr_enable_value  <= 1'b0;
        end else begin
            wr_enable_reg   <= 1'b0; // Default, only set when writing
            wr_enable_value <= 1'b0;
            case (write_state)
                WRITE_IDLE: begin
                    s_axi_awready   <= 1'b1;
                    s_axi_wready    <= 1'b1;
                    s_axi_bvalid    <= 1'b0;
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        // decode address for write
                        if (s_axi_awaddr == ADDR_ENABLE) begin
                            wr_enable_reg   <= 1'b1;
                            wr_enable_value <= s_axi_wdata[0];
                        end
                        s_axi_awready   <= 1'b0;
                        s_axi_wready    <= 1'b0;
                        write_state     <= WRITE_RESP;
                    end
                end
                WRITE_RESP: begin
                    s_axi_bvalid    <= 1'b1;
                    s_axi_bresp     <= RESP_OKAY;
                    if (s_axi_bready && s_axi_bvalid) begin
                        s_axi_bvalid    <= 1'b0;
                        write_state     <= WRITE_IDLE;
                    end
                end
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Read Channel Handler: Handles AXI4-Lite read transactions and register read
// -----------------------------------------------------------------------------
module axi4lite_read_channel #(
    parameter ADDR_ENABLE    = 4'h0,
    parameter ADDR_RST_OUT_N = 4'h4
) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [3:0]   s_axi_araddr,
    input  wire         s_axi_arvalid,
    output reg          s_axi_arready,
    output reg [31:0]   s_axi_rdata,
    output reg [1:0]    s_axi_rresp,
    output reg          s_axi_rvalid,
    input  wire         s_axi_rready,
    input  wire         enable_reg,
    input  wire         rst_out_n_reg
);

    typedef enum reg [1:0] {READ_IDLE, READ_DATA} read_state_t;
    read_state_t read_state;

    localparam RESP_OKAY = 2'b00;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_state      <= READ_IDLE;
            s_axi_arready   <= 1'b0;
            s_axi_rvalid    <= 1'b0;
            s_axi_rdata     <= 32'd0;
            s_axi_rresp     <= RESP_OKAY;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid  <= 1'b0;
                    if (s_axi_arvalid && s_axi_arready) begin
                        s_axi_arready <= 1'b0;
                        s_axi_rvalid  <= 1'b1;
                        case (s_axi_araddr)
                            ADDR_ENABLE:    s_axi_rdata <= {31'd0, enable_reg};
                            ADDR_RST_OUT_N: s_axi_rdata <= {31'd0, rst_out_n_reg};
                            default:        s_axi_rdata <= 32'd0;
                        endcase
                        s_axi_rresp <= RESP_OKAY;
                        read_state  <= READ_DATA;
                    end
                end
                READ_DATA: begin
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid  <= 1'b0;
                        read_state    <= READ_IDLE;
                    end
                end
                default: read_state <= READ_IDLE;
            endcase
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Enable Register Logic: Stores the enable register, written by AXI write
// -----------------------------------------------------------------------------
module enable_reset_register (
    input  wire clk,
    input  wire rst_n,
    input  wire wr_enable_reg,
    input  wire wr_enable_value,
    output reg  enable_reg
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_reg <= 1'b0;
        end else begin
            if (wr_enable_reg) begin
                enable_reg <= wr_enable_value;
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Enabled Reset Synchronizer: Generates reset output based on enable
// -----------------------------------------------------------------------------
module enabled_reset_synchronizer (
    input  wire clk,
    input  wire rst_n,
    input  wire enable_reg,
    output reg  rst_out_n_reg
);

    reg metastable_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            metastable_reg <= 1'b0;
            rst_out_n_reg  <= 1'b0;
        end else begin
            if (enable_reg) begin
                metastable_reg <= 1'b1;
            end
            rst_out_n_reg <= (enable_reg ? metastable_reg : rst_out_n_reg);
        end
    end

endmodule