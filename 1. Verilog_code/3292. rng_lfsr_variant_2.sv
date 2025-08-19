//SystemVerilog
module rng_lfsr_12_axi4lite #(
    parameter ADDR_WIDTH = 4,   // Enough for a few registers
    parameter DATA_WIDTH = 32   // AXI4-Lite data width
)(
    input                   ACLK,
    input                   ARESETN,

    // AXI4-Lite Write Address Channel
    input  [ADDR_WIDTH-1:0] AWADDR,
    input                   AWVALID,
    output                  AWREADY,

    // AXI4-Lite Write Data Channel
    input  [DATA_WIDTH-1:0] WDATA,
    input  [(DATA_WIDTH/8)-1:0] WSTRB,
    input                   WVALID,
    output                  WREADY,

    // AXI4-Lite Write Response Channel
    output [1:0]            BRESP,
    output                  BVALID,
    input                   BREADY,

    // AXI4-Lite Read Address Channel
    input  [ADDR_WIDTH-1:0] ARADDR,
    input                   ARVALID,
    output                  ARREADY,

    // AXI4-Lite Read Data Channel
    output [DATA_WIDTH-1:0] RDATA,
    output [1:0]            RRESP,
    output                  RVALID,
    input                   RREADY
);

    // Internal registers
    reg [3:0] lfsr_state_reg = 4'b1010;
    reg [3:0] lfsr_state_buf1;
    reg [3:0] lfsr_state_buf2;

    // Control register: bit0 = enable
    reg        ctrl_en_reg;

    // AXI4-Lite handshake logic
    reg        awready_reg, wready_reg, bvalid_reg, arready_reg, rvalid_reg;
    reg [1:0]  bresp_reg, rresp_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;

    // Write address/data valid latch
    reg        awvalid_d, wvalid_d;
    reg [ADDR_WIDTH-1:0] awaddr_d;
    reg [DATA_WIDTH-1:0] wdata_d;
    reg [(DATA_WIDTH/8)-1:0] wstrb_d;

    // AXI4-Lite Write Address/Write Data handshake
    wire write_req = AWVALID & WVALID & ~bvalid_reg;

    // AXI4-Lite Read Address handshake
    wire read_req  = ARVALID & ~rvalid_reg;

    // Write response always OKAY
    localparam RESP_OKAY = 2'b00;

    // Address Map
    localparam ADDR_CTRL   = 4'h0; // Control register (enable)
    localparam ADDR_STATE  = 4'h4; // LFSR state (read only)

    // LFSR feedback
    wire feedback = lfsr_state_reg[3] ^ lfsr_state_reg[2];

    // LFSR logic clocked by ACLK
    always @(posedge ACLK) begin
        if (!ARESETN)
            lfsr_state_reg <= 4'b1010;
        else if(ctrl_en_reg)
            lfsr_state_reg <= {lfsr_state_reg[2:0], feedback};
    end

    // Buffer stage 1 for high fanout state signal
    always @(posedge ACLK) begin
        if (!ARESETN)
            lfsr_state_buf1 <= 4'b0;
        else
            lfsr_state_buf1 <= lfsr_state_reg;
    end

    // Buffer stage 2 for additional load balancing
    always @(posedge ACLK) begin
        if (!ARESETN)
            lfsr_state_buf2 <= 4'b0;
        else
            lfsr_state_buf2 <= lfsr_state_buf1;
    end

    // AXI4-Lite write address channel
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            awready_reg <= 1'b0;
            wready_reg  <= 1'b0;
            awvalid_d   <= 1'b0;
            wvalid_d    <= 1'b0;
        end else begin
            // Accept address when both AWVALID and WVALID are high and not already latched
            if (!awvalid_d && AWVALID && WVALID && !awready_reg && !wready_reg) begin
                awaddr_d   <= AWADDR;
                awvalid_d  <= 1'b1;
                wdata_d    <= WDATA;
                wstrb_d    <= WSTRB;
                wvalid_d   <= 1'b1;
                awready_reg <= 1'b1;
                wready_reg  <= 1'b1;
            end else if (bvalid_reg && BREADY) begin
                awvalid_d   <= 1'b0;
                wvalid_d    <= 1'b0;
                awready_reg <= 1'b0;
                wready_reg  <= 1'b0;
            end else begin
                awready_reg <= 1'b0;
                wready_reg  <= 1'b0;
            end
        end
    end

    assign AWREADY = awready_reg;
    assign WREADY  = wready_reg;

    // Write operation and response
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            bvalid_reg  <= 1'b0;
            bresp_reg   <= RESP_OKAY;
            ctrl_en_reg <= 1'b0;
        end else begin
            // Write operation
            if (awvalid_d && wvalid_d && !bvalid_reg) begin
                // Write to control register
                if (awaddr_d[ADDR_WIDTH-1:0] == ADDR_CTRL) begin
                    if (wstrb_d[0])
                        ctrl_en_reg <= wdata_d[0];
                end
                // Cannot write to state register (read only)
                bvalid_reg <= 1'b1;
                bresp_reg  <= RESP_OKAY;
            end else if (bvalid_reg && BREADY) begin
                bvalid_reg <= 1'b0;
            end
        end
    end

    assign BRESP = bresp_reg;
    assign BVALID = bvalid_reg;

    // AXI4-Lite read address channel
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            arready_reg <= 1'b0;
            rvalid_reg  <= 1'b0;
            rresp_reg   <= RESP_OKAY;
            rdata_reg   <= {DATA_WIDTH{1'b0}};
        end else begin
            if (read_req) begin
                arready_reg <= 1'b1;
                rvalid_reg  <= 1'b1;
                rresp_reg   <= RESP_OKAY;
                case (ARADDR[ADDR_WIDTH-1:0])
                    ADDR_CTRL: begin
                        rdata_reg <= {{(DATA_WIDTH-1){1'b0}}, ctrl_en_reg};
                    end
                    ADDR_STATE: begin
                        rdata_reg <= {{(DATA_WIDTH-4){1'b0}}, lfsr_state_buf2};
                    end
                    default: begin
                        rdata_reg <= {DATA_WIDTH{1'b0}};
                    end
                endcase
            end else if (rvalid_reg && RREADY) begin
                arready_reg <= 1'b0;
                rvalid_reg  <= 1'b0;
            end else begin
                arready_reg <= 1'b0;
            end
        end
    end

    assign ARREADY = arready_reg;
    assign RVALID  = rvalid_reg;
    assign RRESP   = rresp_reg;
    assign RDATA   = rdata_reg;

endmodule