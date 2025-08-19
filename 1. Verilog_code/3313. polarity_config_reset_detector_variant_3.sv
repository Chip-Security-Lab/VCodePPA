//SystemVerilog
module axi4lite_reg_if #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32,
    parameter REG_WIDTH  = 4,
    parameter ADDR_POLARITY_CONFIG = 4'h0,
    parameter ADDR_RESET_INPUTS    = 4'h4,
    parameter ADDR_DETECTED_RESETS = 4'h8
)(
    input                       ACLK,
    input                       ARESETn,
    // Write Address Channel
    input  [ADDR_WIDTH-1:0]     AWADDR,
    input                       AWVALID,
    output                      AWREADY,
    // Write Data Channel
    input  [DATA_WIDTH-1:0]     WDATA,
    input  [(DATA_WIDTH/8)-1:0] WSTRB,
    input                       WVALID,
    output                      WREADY,
    // Write Response Channel
    output [1:0]                BRESP,
    output                      BVALID,
    input                       BREADY,
    // Read Address Channel
    input  [ADDR_WIDTH-1:0]     ARADDR,
    input                       ARVALID,
    output                      ARREADY,
    // Read Data Channel
    output [DATA_WIDTH-1:0]     RDATA,
    output [1:0]                RRESP,
    output                      RVALID,
    input                       RREADY,
    // Register Interfaces
    output                      wr_polarity_config,
    output [REG_WIDTH-1:0]      wr_polarity_config_data,
    output                      wr_reset_inputs,
    output [REG_WIDTH-1:0]      wr_reset_inputs_data,
    input  [REG_WIDTH-1:0]      rd_polarity_config,
    input  [REG_WIDTH-1:0]      rd_reset_inputs,
    input  [REG_WIDTH-1:0]      rd_detected_resets
);

    // ------------------- Pipeline Stage 1: Latch Write/Read Address/Data -------------------
    reg                          awvalid_stage1, wvalid_stage1, arvalid_stage1;
    reg  [ADDR_WIDTH-1:0]        awaddr_stage1, araddr_stage1;
    reg  [DATA_WIDTH-1:0]        wdata_stage1;
    reg  [(DATA_WIDTH/8)-1:0]    wstrb_stage1;
    reg                          awready_stage1, wready_stage1, arready_stage1;
    wire                         write_addr_handshake_stage1 = AWVALID && awready_stage1;
    wire                         write_data_handshake_stage1 = WVALID && wready_stage1;
    wire                         read_addr_handshake_stage1  = ARVALID && arready_stage1;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            awvalid_stage1    <= 1'b0;
            wvalid_stage1     <= 1'b0;
            arvalid_stage1    <= 1'b0;
            awaddr_stage1     <= {ADDR_WIDTH{1'b0}};
            wdata_stage1      <= {DATA_WIDTH{1'b0}};
            wstrb_stage1      <= {(DATA_WIDTH/8){1'b0}};
            araddr_stage1     <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (write_addr_handshake_stage1) begin
                awvalid_stage1 <= 1'b1;
                awaddr_stage1  <= AWADDR;
            end else if (awvalid_stage1 && write_data_handshake_stage1) begin
                awvalid_stage1 <= 1'b0;
            end

            if (write_data_handshake_stage1) begin
                wvalid_stage1 <= 1'b1;
                wdata_stage1  <= WDATA;
                wstrb_stage1  <= WSTRB;
            end else if (wvalid_stage1 && write_addr_handshake_stage1) begin
                wvalid_stage1 <= 1'b0;
            end

            if (read_addr_handshake_stage1) begin
                arvalid_stage1 <= 1'b1;
                araddr_stage1  <= ARADDR;
            end else if (arvalid_stage1 && RVALID && RREADY) begin
                arvalid_stage1 <= 1'b0;
            end
        end
    end

    // ------------------- Pipeline Stage 2: Decode Write/Read Command -------------------
    reg                          wr_polarity_config_stage2, wr_reset_inputs_stage2;
    reg  [REG_WIDTH-1:0]         wr_polarity_config_data_stage2, wr_reset_inputs_data_stage2;
    reg                          write_req_valid_stage2, read_req_valid_stage2;
    reg  [ADDR_WIDTH-1:0]        araddr_stage2;
    reg                          bvalid_stage2, rvalid_stage2;
    reg  [1:0]                   bresp_stage2, rresp_stage2;
    reg  [DATA_WIDTH-1:0]        rdata_stage2;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            wr_polarity_config_stage2    <= 1'b0;
            wr_polarity_config_data_stage2 <= {REG_WIDTH{1'b0}};
            wr_reset_inputs_stage2       <= 1'b0;
            wr_reset_inputs_data_stage2  <= {REG_WIDTH{1'b0}};
            write_req_valid_stage2       <= 1'b0;
            read_req_valid_stage2        <= 1'b0;
            araddr_stage2                <= {ADDR_WIDTH{1'b0}};
            bvalid_stage2                <= 1'b0;
            bresp_stage2                 <= 2'b00;
            rvalid_stage2                <= 1'b0;
            rresp_stage2                 <= 2'b00;
            rdata_stage2                 <= {DATA_WIDTH{1'b0}};
        end else begin
            // Write command decode pipeline
            if (awvalid_stage1 && wvalid_stage1 && !write_req_valid_stage2) begin
                wr_polarity_config_stage2     <= (awaddr_stage1 == ADDR_POLARITY_CONFIG) && wstrb_stage1[0];
                wr_polarity_config_data_stage2<= wdata_stage1[REG_WIDTH-1:0];
                wr_reset_inputs_stage2        <= (awaddr_stage1 == ADDR_RESET_INPUTS) && wstrb_stage1[0];
                wr_reset_inputs_data_stage2   <= wdata_stage1[REG_WIDTH-1:0];
                write_req_valid_stage2        <= 1'b1;
                bvalid_stage2                 <= 1'b1;
                bresp_stage2                  <= 2'b00; // OKAY
            end else if (bvalid_stage2 && BREADY) begin
                write_req_valid_stage2        <= 1'b0;
                bvalid_stage2                 <= 1'b0;
            end

            // Read command decode pipeline
            if (arvalid_stage1 && !read_req_valid_stage2) begin
                read_req_valid_stage2         <= 1'b1;
                araddr_stage2                 <= araddr_stage1;
                rvalid_stage2                 <= 1'b1;
                case (araddr_stage1)
                    ADDR_POLARITY_CONFIG: rdata_stage2 <= {{(DATA_WIDTH-REG_WIDTH){1'b0}}, rd_polarity_config};
                    ADDR_RESET_INPUTS:    rdata_stage2 <= {{(DATA_WIDTH-REG_WIDTH){1'b0}}, rd_reset_inputs};
                    ADDR_DETECTED_RESETS: rdata_stage2 <= {{(DATA_WIDTH-REG_WIDTH){1'b0}}, rd_detected_resets};
                    default:              rdata_stage2 <= {DATA_WIDTH{1'b0}};
                endcase
                rresp_stage2                  <= 2'b00; // OKAY
            end else if (rvalid_stage2 && RREADY) begin
                read_req_valid_stage2         <= 1'b0;
                rvalid_stage2                 <= 1'b0;
            end
        end
    end

    // ------------------- Pipeline Stage 3: Output Handshake -------------------
    assign AWREADY = !awvalid_stage1 && !write_req_valid_stage2;
    assign WREADY  = !wvalid_stage1 && !write_req_valid_stage2;
    assign BRESP   = bresp_stage2;
    assign BVALID  = bvalid_stage2;
    assign ARREADY = !arvalid_stage1 && !read_req_valid_stage2;
    assign RDATA   = rdata_stage2;
    assign RRESP   = rresp_stage2;
    assign RVALID  = rvalid_stage2;

    // Write enables for registers (valid only for one cycle)
    assign wr_polarity_config      = wr_polarity_config_stage2 && write_req_valid_stage2;
    assign wr_polarity_config_data = wr_polarity_config_data_stage2;
    assign wr_reset_inputs         = wr_reset_inputs_stage2 && write_req_valid_stage2;
    assign wr_reset_inputs_data    = wr_reset_inputs_data_stage2;

endmodule