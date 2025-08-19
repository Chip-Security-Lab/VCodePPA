//SystemVerilog
module rng_lcg_4_axi4lite #(
    parameter A = 32'h41C64E6D,
    parameter C = 32'h00003039
)(
    input               ACLK,
    input               ARESETN,
    // AXI4-Lite Write Address Channel
    input  [3:0]        AWADDR,
    input               AWVALID,
    output reg          AWREADY,
    // AXI4-Lite Write Data Channel
    input  [31:0]       WDATA,
    input  [3:0]        WSTRB,
    input               WVALID,
    output reg          WREADY,
    // AXI4-Lite Write Response Channel
    output reg [1:0]    BRESP,
    output reg          BVALID,
    input               BREADY,
    // AXI4-Lite Read Address Channel
    input  [3:0]        ARADDR,
    input               ARVALID,
    output reg          ARREADY,
    // AXI4-Lite Read Data Channel
    output reg [31:0]   RDATA,
    output reg [1:0]    RRESP,
    output reg          RVALID,
    input               RREADY
);

    // Internal registers
    reg [31:0] rand_val_pipe4;
    reg        en_pipe3;

    // Write state machine
    typedef enum logic [1:0] {
        WR_IDLE,
        WR_ADDR,
        WR_DATA,
        WR_RESP
    } wr_state_t;
    wr_state_t wr_state_pipe0, wr_state_pipe1, wr_state_pipe2, wr_state_pipe3, wr_state_pipe4, wr_state_next_pipe0;

    // Read state machine
    typedef enum logic [1:0] {
        RD_IDLE,
        RD_ADDR,
        RD_DATA
    } rd_state_t;
    rd_state_t rd_state_pipe0, rd_state_pipe1, rd_state_pipe2, rd_state_pipe3, rd_state_next_pipe0;

    // Write address and data latching
    reg [3:0]  awaddr_pipe0, awaddr_pipe1, awaddr_pipe2;
    reg [31:0] wdata_pipe0, wdata_pipe1, wdata_pipe2;
    reg [3:0]  wstrb_pipe0, wstrb_pipe1, wstrb_pipe2;

    // Constants for AXI response
    localparam [1:0] AXI_RESP_OKAY = 2'b00;
    localparam [1:0] AXI_RESP_SLVERR = 2'b10;

    // Address map
    localparam [3:0] ADDR_RAND_VAL = 4'h0;
    localparam [3:0] ADDR_EN       = 4'h4;

    // Pipeline registers for AXI signals
    reg AWREADY_pipe0, AWREADY_pipe1, AWREADY_pipe2, AWREADY_pipe3, AWREADY_pipe4;
    reg WREADY_pipe0,  WREADY_pipe1,  WREADY_pipe2,  WREADY_pipe3,  WREADY_pipe4;
    reg BVALID_pipe0,  BVALID_pipe1,  BVALID_pipe2,  BVALID_pipe3,  BVALID_pipe4;
    reg [1:0] BRESP_pipe0, BRESP_pipe1, BRESP_pipe2, BRESP_pipe3, BRESP_pipe4;

    // Pipeline registers for read channel
    reg ARREADY_pipe0, ARREADY_pipe1, ARREADY_pipe2, ARREADY_pipe3;
    reg RVALID_pipe0,  RVALID_pipe1,  RVALID_pipe2,  RVALID_pipe3;
    reg [31:0] RDATA_pipe2, RDATA_pipe3, RDATA_pipe4;
    reg [1:0] RRESP_pipe2, RRESP_pipe3, RRESP_pipe4;

    // Write enable pipeline
    reg en_pipe0, en_pipe1, en_pipe2;

    //======================
    // Write State Pipeline
    //======================
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            wr_state_pipe0 <= WR_IDLE;
            wr_state_pipe1 <= WR_IDLE;
            wr_state_pipe2 <= WR_IDLE;
            wr_state_pipe3 <= WR_IDLE;
            wr_state_pipe4 <= WR_IDLE;
            AWREADY_pipe0  <= 1'b0;
            AWREADY_pipe1  <= 1'b0;
            AWREADY_pipe2  <= 1'b0;
            AWREADY_pipe3  <= 1'b0;
            AWREADY_pipe4  <= 1'b0;
            WREADY_pipe0   <= 1'b0;
            WREADY_pipe1   <= 1'b0;
            WREADY_pipe2   <= 1'b0;
            WREADY_pipe3   <= 1'b0;
            WREADY_pipe4   <= 1'b0;
            BVALID_pipe0   <= 1'b0;
            BVALID_pipe1   <= 1'b0;
            BVALID_pipe2   <= 1'b0;
            BVALID_pipe3   <= 1'b0;
            BVALID_pipe4   <= 1'b0;
            BRESP_pipe0    <= AXI_RESP_OKAY;
            BRESP_pipe1    <= AXI_RESP_OKAY;
            BRESP_pipe2    <= AXI_RESP_OKAY;
            BRESP_pipe3    <= AXI_RESP_OKAY;
            BRESP_pipe4    <= AXI_RESP_OKAY;
            awaddr_pipe0   <= 4'h0;
            awaddr_pipe1   <= 4'h0;
            awaddr_pipe2   <= 4'h0;
            wdata_pipe0    <= 32'h0;
            wdata_pipe1    <= 32'h0;
            wdata_pipe2    <= 32'h0;
            wstrb_pipe0    <= 4'h0;
            wstrb_pipe1    <= 4'h0;
            wstrb_pipe2    <= 4'h0;
            en_pipe0       <= 1'b0;
            en_pipe1       <= 1'b0;
            en_pipe2       <= 1'b0;
            en_pipe3       <= 1'b0;
        end else begin
            // Pipeline advance
            wr_state_pipe4 <= wr_state_pipe3;
            wr_state_pipe3 <= wr_state_pipe2;
            wr_state_pipe2 <= wr_state_pipe1;
            wr_state_pipe1 <= wr_state_pipe0;
            wr_state_pipe0 <= wr_state_next_pipe0;

            AWREADY_pipe4  <= AWREADY_pipe3;
            AWREADY_pipe3  <= AWREADY_pipe2;
            AWREADY_pipe2  <= AWREADY_pipe1;
            AWREADY_pipe1  <= AWREADY_pipe0;
            // AWREADY_pipe0 assigned below

            WREADY_pipe4   <= WREADY_pipe3;
            WREADY_pipe3   <= WREADY_pipe2;
            WREADY_pipe2   <= WREADY_pipe1;
            WREADY_pipe1   <= WREADY_pipe0;
            // WREADY_pipe0 assigned below

            BVALID_pipe4   <= BVALID_pipe3;
            BVALID_pipe3   <= BVALID_pipe2;
            BVALID_pipe2   <= BVALID_pipe1;
            BVALID_pipe1   <= BVALID_pipe0;
            // BVALID_pipe0 assigned below

            BRESP_pipe4    <= BRESP_pipe3;
            BRESP_pipe3    <= BRESP_pipe2;
            BRESP_pipe2    <= BRESP_pipe1;
            BRESP_pipe1    <= BRESP_pipe0;
            // BRESP_pipe0 assigned below

            awaddr_pipe2   <= awaddr_pipe1;
            awaddr_pipe1   <= awaddr_pipe0;
            wdata_pipe2    <= wdata_pipe1;
            wdata_pipe1    <= wdata_pipe0;
            wstrb_pipe2    <= wstrb_pipe1;
            wstrb_pipe1    <= wstrb_pipe0;

            en_pipe3       <= en_pipe2;
            en_pipe2       <= en_pipe1;
            en_pipe1       <= en_pipe0;

            // Stage 0: IDLE/ADDR
            case (wr_state_pipe0)
                WR_IDLE: begin
                    AWREADY_pipe0 <= 1'b1;
                    WREADY_pipe0  <= 1'b0;
                    BVALID_pipe0  <= 1'b0;
                    BRESP_pipe0   <= AXI_RESP_OKAY;
                end
                WR_ADDR: begin
                    AWREADY_pipe0 <= 1'b0;
                    WREADY_pipe0  <= 1'b1;
                    BVALID_pipe0  <= 1'b0;
                    BRESP_pipe0   <= AXI_RESP_OKAY;
                end
                WR_DATA: begin
                    AWREADY_pipe0 <= 1'b0;
                    WREADY_pipe0  <= 1'b0;
                    BVALID_pipe0  <= 1'b0;
                    BRESP_pipe0   <= AXI_RESP_OKAY;
                end
                WR_RESP: begin
                    AWREADY_pipe0 <= 1'b0;
                    WREADY_pipe0  <= 1'b0;
                    BVALID_pipe0  <= 1'b1;
                    BRESP_pipe0   <= AXI_RESP_OKAY;
                end
                default: begin
                    AWREADY_pipe0 <= 1'b0;
                    WREADY_pipe0  <= 1'b0;
                    BVALID_pipe0  <= 1'b0;
                    BRESP_pipe0   <= AXI_RESP_OKAY;
                end
            endcase

            // Latch address and data for write at Stage 0
            if (AWREADY_pipe0 && AWVALID) begin
                awaddr_pipe0 <= AWADDR;
            end
            if (WREADY_pipe0 && WVALID) begin
                wdata_pipe0 <= WDATA;
                wstrb_pipe0 <= WSTRB;
            end

            // Stage 2: actual register write for EN
            if ((wr_state_pipe2 == WR_DATA) && (awaddr_pipe2 == ADDR_EN)) begin
                if (wstrb_pipe2[0])
                    en_pipe0 <= wdata_pipe2[0];
            end

            // BVALID handshake, clear at stage4
            if (BVALID_pipe4 && BREADY)
                BVALID_pipe4 <= 1'b0;
        end
    end

    // Write state next logic (Pipe0)
    always @(*) begin
        wr_state_next_pipe0 = wr_state_pipe0;
        case (wr_state_pipe0)
            WR_IDLE: begin
                if (AWVALID) begin
                    wr_state_next_pipe0 = WR_ADDR;
                end
            end
            WR_ADDR: begin
                if (WVALID) begin
                    wr_state_next_pipe0 = WR_DATA;
                end
            end
            WR_DATA: begin
                wr_state_next_pipe0 = WR_RESP;
            end
            WR_RESP: begin
                if (BVALID_pipe4 && BREADY) begin
                    wr_state_next_pipe0 = WR_IDLE;
                end
            end
            default: wr_state_next_pipe0 = WR_IDLE;
        endcase
    end

    //=========================
    // Read State Machine Pipelined
    //=========================
    reg [3:0] araddr_pipe0, araddr_pipe1, araddr_pipe2;
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            rd_state_pipe0 <= RD_IDLE;
            rd_state_pipe1 <= RD_IDLE;
            rd_state_pipe2 <= RD_IDLE;
            rd_state_pipe3 <= RD_IDLE;
            ARREADY_pipe0  <= 1'b0;
            ARREADY_pipe1  <= 1'b0;
            ARREADY_pipe2  <= 1'b0;
            ARREADY_pipe3  <= 1'b0;
            RVALID_pipe0   <= 1'b0;
            RVALID_pipe1   <= 1'b0;
            RVALID_pipe2   <= 1'b0;
            RVALID_pipe3   <= 1'b0;
            RDATA_pipe2    <= 32'h0;
            RDATA_pipe3    <= 32'h0;
            RDATA_pipe4    <= 32'h0;
            RRESP_pipe2    <= AXI_RESP_OKAY;
            RRESP_pipe3    <= AXI_RESP_OKAY;
            RRESP_pipe4    <= AXI_RESP_OKAY;
            araddr_pipe0   <= 4'h0;
            araddr_pipe1   <= 4'h0;
            araddr_pipe2   <= 4'h0;
        end else begin
            // Pipeline advance
            rd_state_pipe3 <= rd_state_pipe2;
            rd_state_pipe2 <= rd_state_pipe1;
            rd_state_pipe1 <= rd_state_pipe0;
            rd_state_pipe0 <= rd_state_next_pipe0;

            ARREADY_pipe3  <= ARREADY_pipe2;
            ARREADY_pipe2  <= ARREADY_pipe1;
            ARREADY_pipe1  <= ARREADY_pipe0;
            // ARREADY_pipe0 assigned below

            RVALID_pipe3   <= RVALID_pipe2;
            RVALID_pipe2   <= RVALID_pipe1;
            RVALID_pipe1   <= RVALID_pipe0;
            // RVALID_pipe0 assigned below

            RDATA_pipe4    <= RDATA_pipe3;
            RDATA_pipe3    <= RDATA_pipe2;
            RRESP_pipe4    <= RRESP_pipe3;
            RRESP_pipe3    <= RRESP_pipe2;

            araddr_pipe2   <= araddr_pipe1;
            araddr_pipe1   <= araddr_pipe0;

            // Stage 0: IDLE/ADDR
            case (rd_state_pipe0)
                RD_IDLE: begin
                    ARREADY_pipe0 <= 1'b1;
                    RVALID_pipe0  <= 1'b0;
                end
                RD_ADDR: begin
                    ARREADY_pipe0 <= 1'b0;
                    RVALID_pipe0  <= 1'b0;
                end
                RD_DATA: begin
                    ARREADY_pipe0 <= 1'b0;
                    RVALID_pipe0  <= 1'b1;
                end
                default: begin
                    ARREADY_pipe0 <= 1'b0;
                    RVALID_pipe0  <= 1'b0;
                end
            endcase

            // Latch address for read at Stage 0
            if (ARREADY_pipe0 && ARVALID) begin
                araddr_pipe0 <= ARADDR;
            end

            // Stage 2: latch read data
            if (rd_state_pipe2 == RD_ADDR) begin
                case (araddr_pipe2)
                    ADDR_RAND_VAL: begin
                        RDATA_pipe2 <= rand_val_pipe4;
                        RRESP_pipe2 <= AXI_RESP_OKAY;
                    end
                    ADDR_EN: begin
                        RDATA_pipe2 <= {31'b0, en_pipe3};
                        RRESP_pipe2 <= AXI_RESP_OKAY;
                    end
                    default: begin
                        RDATA_pipe2 <= 32'h0;
                        RRESP_pipe2 <= AXI_RESP_SLVERR;
                    end
                endcase
            end

            // RVALID handshake, clear at stage3
            if (RVALID_pipe3 && RREADY)
                RVALID_pipe3 <= 1'b0;
        end
    end

    // Read state next logic (Pipe0)
    always @(*) begin
        rd_state_next_pipe0 = rd_state_pipe0;
        case (rd_state_pipe0)
            RD_IDLE: begin
                if (ARVALID) begin
                    rd_state_next_pipe0 = RD_ADDR;
                end
            end
            RD_ADDR: begin
                rd_state_next_pipe0 = RD_DATA;
            end
            RD_DATA: begin
                if (RVALID_pipe3 && RREADY) begin
                    rd_state_next_pipe0 = RD_IDLE;
                end
            end
            default: rd_state_next_pipe0 = RD_IDLE;
        endcase
    end

    //======================
    // LCG RNG Core Deep Pipelined
    //======================
    reg [31:0] rand_val_pipe0, rand_val_pipe1, rand_val_pipe2, rand_val_pipe3;
    reg [31:0] mult_input_a_pipe1, mult_input_b_pipe1;
    reg [63:0] mult_result_pipe2;
    reg [31:0] add_input_pipe3;
    reg [31:0] add_result_pipe4;

    // Insert pipeline stage between multiply and add for critical path cut
    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            rand_val_pipe0     <= 32'h12345678;
            rand_val_pipe1     <= 32'h0;
            rand_val_pipe2     <= 32'h0;
            rand_val_pipe3     <= 32'h0;
            rand_val_pipe4     <= 32'h0;
            mult_input_a_pipe1 <= 32'h0;
            mult_input_b_pipe1 <= 32'h0;
            mult_result_pipe2  <= 64'h0;
            add_input_pipe3    <= 32'h0;
            add_result_pipe4   <= 32'h0;
        end else begin
            // Stage 0: latch input for LCG
            if (en_pipe3) begin
                rand_val_pipe0 <= rand_val_pipe4;
            end else begin
                rand_val_pipe0 <= rand_val_pipe4;
            end

            // Stage 1: prepare for multiply
            if (en_pipe3) begin
                mult_input_a_pipe1 <= rand_val_pipe0;
                mult_input_b_pipe1 <= A;
            end else begin
                mult_input_a_pipe1 <= mult_input_a_pipe1;
                mult_input_b_pipe1 <= mult_input_b_pipe1;
            end

            // Stage 2: multiply
            if (en_pipe3) begin
                mult_result_pipe2 <= mult_input_a_pipe1 * mult_input_b_pipe1;
            end else begin
                mult_result_pipe2 <= mult_result_pipe2;
            end

            // Stage 3: pipeline cut, register multiply result lower 32 bits
            if (en_pipe3) begin
                add_input_pipe3 <= mult_result_pipe2[31:0];
            end else begin
                add_input_pipe3 <= add_input_pipe3;
            end

            // Stage 4: add
            if (en_pipe3) begin
                add_result_pipe4 <= add_input_pipe3 + C;
            end else begin
                add_result_pipe4 <= add_result_pipe4;
            end

            // Stage 5: output register
            if (en_pipe3) begin
                rand_val_pipe4 <= add_result_pipe4;
            end else begin
                rand_val_pipe4 <= rand_val_pipe4;
            end
        end
    end

    //======================
    // Output Assignments
    //======================
    always @(*) begin
        AWREADY = AWREADY_pipe4;
        WREADY  = WREADY_pipe4;
        BVALID  = BVALID_pipe4;
        BRESP   = BRESP_pipe4;
        ARREADY = ARREADY_pipe3;
        RVALID  = RVALID_pipe3;
        RDATA   = RDATA_pipe4;
        RRESP   = RRESP_pipe4;
    end

endmodule