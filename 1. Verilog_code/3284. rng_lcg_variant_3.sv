//SystemVerilog
module rng_lcg_4_axi4lite #(
    parameter A = 32'h41C64E6D,
    parameter C = 32'h00003039
)(
    input               ACLK,
    input               ARESETn,
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

    // Internal pipeline registers
    reg [31:0] rand_val_stage0, rand_val_stage1, rand_val_stage2;
    reg        en_reg_stage0, en_reg_stage1;
    reg        en_reg;
    reg        lcg_valid_stage0, lcg_valid_stage1, lcg_valid_stage2;
    reg        lcg_flush;

    // AXI4-Lite pipeline state registers
    reg aw_hs_stage0, aw_hs_stage1, aw_hs_stage2;
    reg w_hs_stage0, w_hs_stage1, w_hs_stage2;
    reg ar_hs_stage0, ar_hs_stage1, ar_hs_stage2;

    reg [3:0] awaddr_stage0, awaddr_stage1;
    reg [3:0] araddr_stage0, araddr_stage1;

    reg [31:0] wdata_stage0, wdata_stage1;
    reg [3:0] wstrb_stage0, wstrb_stage1;

    // Write handshake
    wire write_en_stage0 = AWVALID && WVALID && ~aw_hs_stage0 && ~w_hs_stage0;
    wire write_en_stage1 = aw_hs_stage0 && w_hs_stage0 && ~aw_hs_stage1 && ~w_hs_stage1;

    // Read handshake
    wire read_en_stage0 = ARVALID && ~ar_hs_stage0;
    wire read_en_stage1 = ar_hs_stage0 && ~ar_hs_stage1;

    // Pipeline flush logic
    always @(posedge ACLK or negedge ARESETn) begin
        if (~ARESETn) begin
            lcg_flush <= 1'b1;
        end else if (BVALID && BREADY) begin
            lcg_flush <= 1'b1;
        end else if (RVALID && RREADY) begin
            lcg_flush <= 1'b1;
        end else if (write_en_stage0 || read_en_stage0) begin
            lcg_flush <= 1'b0;
        end
    end

    // Write Address and Data handshake logic - Stage 0
    always @(posedge ACLK or negedge ARESETn) begin
        if (~ARESETn) begin
            AWREADY      <= 1'b0;
            WREADY       <= 1'b0;
            aw_hs_stage0 <= 1'b0;
            w_hs_stage0  <= 1'b0;
            awaddr_stage0 <= 4'b0;
            wdata_stage0  <= 32'b0;
            wstrb_stage0  <= 4'b0;
        end else begin
            if (~aw_hs_stage0 && AWVALID) begin
                AWREADY      <= 1'b1;
                aw_hs_stage0 <= 1'b1;
                awaddr_stage0 <= AWADDR;
            end else begin
                AWREADY <= 1'b0;
            end

            if (~w_hs_stage0 && WVALID) begin
                WREADY      <= 1'b1;
                w_hs_stage0 <= 1'b1;
                wdata_stage0  <= WDATA;
                wstrb_stage0  <= WSTRB;
            end else begin
                WREADY <= 1'b0;
            end

            if (BVALID && BREADY) begin
                aw_hs_stage0 <= 1'b0;
                w_hs_stage0  <= 1'b0;
            end
        end
    end

    // Write Address and Data handshake logic - Stage 1
    always @(posedge ACLK or negedge ARESETn) begin
        if (~ARESETn) begin
            aw_hs_stage1 <= 1'b0;
            w_hs_stage1  <= 1'b0;
            awaddr_stage1 <= 4'b0;
            wdata_stage1  <= 32'b0;
            wstrb_stage1  <= 4'b0;
        end else begin
            if (write_en_stage1) begin
                aw_hs_stage1 <= 1'b1;
                w_hs_stage1  <= 1'b1;
                awaddr_stage1 <= awaddr_stage0;
                wdata_stage1  <= wdata_stage0;
                wstrb_stage1  <= wstrb_stage0;
            end else if (BVALID && BREADY) begin
                aw_hs_stage1 <= 1'b0;
                w_hs_stage1  <= 1'b0;
            end
        end
    end

    // Write Address and Data handshake logic - Stage 2 (for BVALID timing)
    always @(posedge ACLK or negedge ARESETn) begin
        if (~ARESETn) begin
            aw_hs_stage2 <= 1'b0;
            w_hs_stage2 <= 1'b0;
        end else begin
            if (aw_hs_stage1 && w_hs_stage1 && ~aw_hs_stage2 && ~w_hs_stage2) begin
                aw_hs_stage2 <= 1'b1;
                w_hs_stage2  <= 1'b1;
            end else if (BVALID && BREADY) begin
                aw_hs_stage2 <= 1'b0;
                w_hs_stage2  <= 1'b0;
            end
        end
    end

    // AXI4-Lite Write Response logic (Stage 2)
    always @(posedge ACLK or negedge ARESETn) begin
        if (~ARESETn) begin
            BVALID <= 1'b0;
            BRESP  <= 2'b00;
        end else begin
            if (aw_hs_stage2 && w_hs_stage2 && ~BVALID) begin
                BVALID <= 1'b1;
                BRESP  <= 2'b00; // OKAY
            end else if (BVALID && BREADY) begin
                BVALID <= 1'b0;
            end
        end
    end

    // AXI4-Lite Read Address handshake logic - Stage 0
    always @(posedge ACLK or negedge ARESETn) begin
        if (~ARESETn) begin
            ARREADY      <= 1'b0;
            ar_hs_stage0 <= 1'b0;
            araddr_stage0 <= 4'b0;
        end else begin
            if (~ar_hs_stage0 && ARVALID) begin
                ARREADY      <= 1'b1;
                ar_hs_stage0 <= 1'b1;
                araddr_stage0 <= ARADDR;
            end else begin
                ARREADY <= 1'b0;
            end

            if (RVALID && RREADY) begin
                ar_hs_stage0 <= 1'b0;
            end
        end
    end

    // AXI4-Lite Read Address handshake logic - Stage 1
    always @(posedge ACLK or negedge ARESETn) begin
        if (~ARESETn) begin
            ar_hs_stage1 <= 1'b0;
            araddr_stage1 <= 4'b0;
        end else begin
            if (ar_hs_stage0 && ~ar_hs_stage1) begin
                ar_hs_stage1 <= 1'b1;
                araddr_stage1 <= araddr_stage0;
            end else if (RVALID && RREADY) begin
                ar_hs_stage1 <= 1'b0;
            end
        end
    end

    // AXI4-Lite Read Address handshake logic - Stage 2 (for RVALID timing)
    always @(posedge ACLK or negedge ARESETn) begin
        if (~ARESETn) begin
            ar_hs_stage2 <= 1'b0;
        end else begin
            if (ar_hs_stage1 && ~ar_hs_stage2) begin
                ar_hs_stage2 <= 1'b1;
            end else if (RVALID && RREADY) begin
                ar_hs_stage2 <= 1'b0;
            end
        end
    end

    // AXI4-Lite Read Data channel logic (Stage 2)
    always @(posedge ACLK or negedge ARESETn) begin
        if (~ARESETn) begin
            RVALID <= 1'b0;
            RDATA  <= 32'b0;
            RRESP  <= 2'b00;
        end else begin
            if (ar_hs_stage2 && ~RVALID) begin
                case (araddr_stage1[3:2])
                    2'b00: RDATA <= rand_val_stage2;
                    2'b01: RDATA <= 32'b0; // Reserved for future registers
                    default: RDATA <= 32'b0;
                endcase
                RVALID <= 1'b1;
                RRESP  <= 2'b00; // OKAY
            end else if (RVALID && RREADY) begin
                RVALID <= 1'b0;
            end
        end
    end

    // Control register write logic (en_reg) - pipelined
    always @(posedge ACLK or negedge ARESETn) begin
        if (~ARESETn) begin
            en_reg_stage0 <= 1'b0;
            en_reg_stage1 <= 1'b0;
            en_reg        <= 1'b0;
        end else begin
            if (aw_hs_stage1 && w_hs_stage1 && awaddr_stage1[3:2] == 2'b01) begin
                en_reg_stage0 <= wdata_stage1[0];
            end

            en_reg_stage1 <= en_reg_stage0;
            if (aw_hs_stage2 && w_hs_stage2 && awaddr_stage1[3:2] == 2'b01) begin
                en_reg <= en_reg_stage1;
            end
        end
    end

    // LCG random value logic - 3-stage pipeline
    // Stage 0: Capture enable
    always @(posedge ACLK or negedge ARESETn) begin
        if (~ARESETn) begin
            rand_val_stage0 <= 32'h12345678;
            lcg_valid_stage0 <= 1'b0;
        end else begin
            if (en_reg) begin
                rand_val_stage0 <= rand_val_stage2;
                lcg_valid_stage0 <= 1'b1;
            end else begin
                rand_val_stage0 <= rand_val_stage2;
                lcg_valid_stage0 <= 1'b0;
            end
        end
    end

    // Stage 1: Multiply
    reg [63:0] lcg_mult_stage1;
    always @(posedge ACLK or negedge ARESETn) begin
        if (~ARESETn) begin
            lcg_mult_stage1 <= 64'b0;
            rand_val_stage1 <= 32'h12345678;
            lcg_valid_stage1 <= 1'b0;
        end else begin
            if (lcg_valid_stage0) begin
                lcg_mult_stage1 <= rand_val_stage0 * A;
                rand_val_stage1 <= rand_val_stage0;
                lcg_valid_stage1 <= 1'b1;
            end else begin
                lcg_mult_stage1 <= lcg_mult_stage1;
                rand_val_stage1 <= rand_val_stage1;
                lcg_valid_stage1 <= 1'b0;
            end
        end
    end

    // Stage 2: Add and register output
    always @(posedge ACLK or negedge ARESETn) begin
        if (~ARESETn) begin
            rand_val_stage2 <= 32'h12345678;
            lcg_valid_stage2 <= 1'b0;
        end else begin
            if (lcg_valid_stage1) begin
                rand_val_stage2 <= lcg_mult_stage1[31:0] + C;
                lcg_valid_stage2 <= 1'b1;
            end else begin
                rand_val_stage2 <= rand_val_stage2;
                lcg_valid_stage2 <= 1'b0;
            end
        end
    end

endmodule