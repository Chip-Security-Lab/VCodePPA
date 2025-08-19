//SystemVerilog
module reset_history_tracker_axi4lite (
    input  wire         clk,
    input  wire         rst_n,
    // AXI4-Lite Slave Interface
    input  wire [3:0]   s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,
    input  wire [15:0]  s_axi_wdata,
    input  wire [1:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,
    output reg [1:0]    s_axi_bresp,
    output reg          s_axi_bvalid,
    input  wire         s_axi_bready,
    input  wire [3:0]   s_axi_araddr,
    input  wire         s_axi_arvalid,
    output reg          s_axi_arready,
    output reg [15:0]   s_axi_rdata,
    output reg [1:0]    s_axi_rresp,
    output reg          s_axi_rvalid,
    input  wire         s_axi_rready,
    // Reset source inputs
    input  wire         por_n,
    input  wire         wdt_n,
    input  wire         soft_n,
    input  wire         ext_n
);

    // Address map
    localparam ADDR_RESET_HISTORY     = 4'h0;
    localparam ADDR_CURRENT_SOURCE    = 4'h4;
    localparam ADDR_CLEAR_HISTORY     = 4'h8;

    reg  [3:0]   current_reset_source;
    reg  [15:0]  reset_history;
    wire [3:0]   detected_sources;
    reg  [3:0]   prev_sources;
    wire         new_reset_event;
    reg          clear_history_req;
    reg          clear_history_req_d;

    assign detected_sources = {~ext_n, ~soft_n, ~wdt_n, ~por_n};
    assign new_reset_event = |(detected_sources & ~prev_sources);

    // Write address handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
        end else begin
            if (~s_axi_awready && s_axi_awvalid)
                s_axi_awready <= 1'b1;
            else if (s_axi_awready && s_axi_wvalid)
                s_axi_awready <= 1'b0;
        end
    end

    // Write data handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wready <= 1'b0;
        end else begin
            if (~s_axi_wready && s_axi_wvalid)
                s_axi_wready <= 1'b1;
            else if (s_axi_wready && s_axi_awvalid)
                s_axi_wready <= 1'b0;
        end
    end

    // Write response generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Read address handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid)
                s_axi_arready <= 1'b1;
            else
                s_axi_arready <= 1'b0;
        end
    end

    // Read data channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= 16'b0;
        end else begin
            if (s_axi_arready && s_axi_arvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;
                case (s_axi_araddr[3:0])
                    ADDR_RESET_HISTORY:   s_axi_rdata <= reset_history;
                    ADDR_CURRENT_SOURCE:  s_axi_rdata <= {12'b0, current_reset_source};
                    default:              s_axi_rdata <= 16'b0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Clear history request detection (write to ADDR_CLEAR_HISTORY)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clear_history_req   <= 1'b0;
            clear_history_req_d <= 1'b0;
        end else begin
            clear_history_req_d <= clear_history_req;
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
                if (s_axi_awaddr[3:0] == ADDR_CLEAR_HISTORY)
                    clear_history_req <= 1'b1;
                else
                    clear_history_req <= 1'b0;
            end else begin
                clear_history_req <= 1'b0;
            end
        end
    end

    // Core logic: reset history and event tracking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_sources         <= 4'b0000;
            current_reset_source <= 4'b0000;
            reset_history        <= 16'h0000;
        end else begin
            prev_sources         <= detected_sources;
            current_reset_source <= detected_sources;

            if (clear_history_req && ~clear_history_req_d) begin
                reset_history <= 16'h0000;
            end else if (new_reset_event) begin
                reset_history <= {reset_history[11:0], detected_sources};
            end
        end
    end

endmodule