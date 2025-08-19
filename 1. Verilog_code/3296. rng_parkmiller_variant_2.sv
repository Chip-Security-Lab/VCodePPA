//SystemVerilog
module rng_parkmiller_16_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input                   clk,
    input                   rst_n,

    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] s_axi_awaddr,
    input                   s_axi_awvalid,
    output                  s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  [31:0]           s_axi_wdata,
    input  [3:0]            s_axi_wstrb,
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
    output [31:0]           s_axi_rdata,
    output [1:0]            s_axi_rresp,
    output                  s_axi_rvalid,
    input                   s_axi_rready
);

    // Internal registers
    reg [31:0] rand_state;
    reg        en_reg;

    // AXI4-Lite handshake registers
    reg        awready_reg;
    reg        wready_reg;
    reg        bvalid_reg;
    reg [1:0]  bresp_reg;
    reg        arready_reg;
    reg        rvalid_reg;
    reg [31:0] rdata_reg;
    reg [1:0]  rresp_reg;

    // Write address and data latching
    reg [ADDR_WIDTH-1:0] awaddr_reg;

    // Write FSM
    wire write_en = s_axi_awvalid & s_axi_wvalid & ~bvalid_reg;

    // Read FSM
    wire read_en  = s_axi_arvalid & ~rvalid_reg;

    // Core logic: Park-Miller RNG
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rand_state <= 32'd1;
            en_reg     <= 1'b0;
        end else begin
            // Write to enable or reset
            if (write_en) begin
                case (awaddr_reg)
                    4'h0: begin // Control register
                        en_reg <= s_axi_wdata[0];
                        if (s_axi_wdata[1]) // Reset bit
                            rand_state <= 32'd1;
                    end
                    default: ;
                endcase
            end

            // RNG operation
            if (en_reg) begin
                rand_state <= (rand_state * 32'd16807) % 32'd2147483647;
            end
        end
    end

    // Write Address Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            awready_reg <= 1'b0;
            awaddr_reg  <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (~awready_reg && s_axi_awvalid && s_axi_wvalid && ~bvalid_reg) begin
                awready_reg <= 1'b1;
                awaddr_reg  <= s_axi_awaddr;
            end else begin
                awready_reg <= 1'b0;
            end
        end
    end

    // Write Data Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wready_reg <= 1'b0;
        end else begin
            if (~wready_reg && s_axi_awvalid && s_axi_wvalid && ~bvalid_reg) begin
                wready_reg <= 1'b1;
            end else begin
                wready_reg <= 1'b0;
            end
        end
    end

    // Write Response Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;
        end else begin
            if (write_en) begin
                bvalid_reg <= 1'b1;
                bresp_reg  <= 2'b00;
            end else if (bvalid_reg && s_axi_bready) begin
                bvalid_reg <= 1'b0;
            end
        end
    end

    // Read Address Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arready_reg <= 1'b0;
        end else begin
            if (~arready_reg && s_axi_arvalid && ~rvalid_reg) begin
                arready_reg <= 1'b1;
            end else begin
                arready_reg <= 1'b0;
            end
        end
    end

    // Read Data Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvalid_reg <= 1'b0;
            rdata_reg  <= 32'b0;
            rresp_reg  <= 2'b00;
        end else begin
            if (read_en) begin
                rvalid_reg <= 1'b1;
                case (s_axi_araddr)
                    4'h0: rdata_reg <= {30'b0, en_reg, (rand_state == 32'd1)};
                    4'h4: rdata_reg <= rand_state;
                    default: rdata_reg <= 32'b0;
                endcase
                rresp_reg <= 2'b00;
            end else if (rvalid_reg && s_axi_rready) begin
                rvalid_reg <= 1'b0;
            end
        end
    end

    assign s_axi_awready = awready_reg;
    assign s_axi_wready  = wready_reg;
    assign s_axi_bresp   = bresp_reg;
    assign s_axi_bvalid  = bvalid_reg;
    assign s_axi_arready = arready_reg;
    assign s_axi_rdata   = rdata_reg;
    assign s_axi_rresp   = rresp_reg;
    assign s_axi_rvalid  = rvalid_reg;

endmodule