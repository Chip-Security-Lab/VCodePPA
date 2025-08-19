//SystemVerilog
module bcd2bin_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input  wire             ACLK,
    input  wire             ARESETN,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0]  S_AXI_AWADDR,
    input  wire                   S_AXI_AWVALID,
    output reg                    S_AXI_AWREADY,

    // AXI4-Lite Write Data Channel
    input  wire [31:0]            S_AXI_WDATA,
    input  wire [3:0]             S_AXI_WSTRB,
    input  wire                   S_AXI_WVALID,
    output reg                    S_AXI_WREADY,

    // AXI4-Lite Write Response Channel
    output reg [1:0]              S_AXI_BRESP,
    output reg                    S_AXI_BVALID,
    input  wire                   S_AXI_BREADY,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0]  S_AXI_ARADDR,
    input  wire                   S_AXI_ARVALID,
    output reg                    S_AXI_ARREADY,

    // AXI4-Lite Read Data Channel
    output reg [31:0]             S_AXI_RDATA,
    output reg [1:0]              S_AXI_RRESP,
    output reg                    S_AXI_RVALID,
    input  wire                   S_AXI_RREADY
);

    // Address mapping (4-bit address, 16 locations, only 2 used)
    localparam ADDR_BCD_INPUT  = 4'h0;
    localparam ADDR_BIN_OUTPUT = 4'h4;

    // Write FSM
    reg aw_en_stage1;

    // Input latching registers for BCD
    reg  [11:0] bcd_input_reg_stage1;
    reg  [11:0] bcd_input_reg_stage2;
    reg  [11:0] bcd_input_reg_stage3;

    // Pipeline registers for BCD to Binary conversion
    reg [7:0] hundreds_stage1;
    reg [7:0] hundreds_stage2;
    reg [7:0] tens_stage1;
    reg [7:0] tens_stage2;
    reg [7:0] ones_stage1;
    reg [7:0] ones_stage2;

    reg [9:0] binary_sum_stage1;
    reg [9:0] binary_sum_stage2;

    // Write address handshake
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            aw_en_stage1 <= 1'b1;
        end else begin
            if (!S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WVALID && aw_en_stage1) begin
                S_AXI_AWREADY <= 1'b1;
                aw_en_stage1 <= 1'b0;
            end else if (S_AXI_BVALID && S_AXI_BREADY) begin
                S_AXI_AWREADY <= 1'b0;
                aw_en_stage1 <= 1'b1;
            end else begin
                S_AXI_AWREADY <= 1'b0;
            end
        end
    end

    // Write data handshake
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            S_AXI_WREADY <= 1'b0;
        end else begin
            if (!S_AXI_WREADY && S_AXI_AWVALID && S_AXI_WVALID && aw_en_stage1) begin
                S_AXI_WREADY <= 1'b1;
            end else begin
                S_AXI_WREADY <= 1'b0;
            end
        end
    end

    // BCD input register pipeline stage 1 (write)
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            bcd_input_reg_stage1 <= 12'd0;
        end else if (S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWREADY && S_AXI_AWVALID) begin
            if (S_AXI_AWADDR[ADDR_WIDTH-1:0] == ADDR_BCD_INPUT) begin
                bcd_input_reg_stage1 <= bcd_input_reg_stage1;
                if (S_AXI_WSTRB[1]) bcd_input_reg_stage1[11:8] <= S_AXI_WDATA[11:8];
                if (S_AXI_WSTRB[1] | S_AXI_WSTRB[0]) bcd_input_reg_stage1[7:0] <= S_AXI_WDATA[7:0];
            end
        end
    end

    // Pipeline stage 2 for BCD input
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            bcd_input_reg_stage2 <= 12'd0;
        end else begin
            bcd_input_reg_stage2 <= bcd_input_reg_stage1;
        end
    end

    // Pipeline stage 3 for BCD input
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            bcd_input_reg_stage3 <= 12'd0;
        end else begin
            bcd_input_reg_stage3 <= bcd_input_reg_stage2;
        end
    end

    // Pipeline stage 1: Calculate hundreds, tens, and ones (combinational to registered)
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            hundreds_stage1 <= 8'd0;
            tens_stage1 <= 8'd0;
            ones_stage1 <= 8'd0;
        end else begin
            hundreds_stage1 <= {4'b0, bcd_input_reg_stage2[11:8]};
            tens_stage1     <= {4'b0, bcd_input_reg_stage2[7:4]};
            ones_stage1     <= {4'b0, bcd_input_reg_stage2[3:0]};
        end
    end

    // Pipeline stage 2: Multiply by weights (100, 10)
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            hundreds_stage2 <= 8'd0;
            tens_stage2 <= 8'd0;
            ones_stage2 <= 8'd0;
        end else begin
            hundreds_stage2 <= hundreds_stage1 * 8'd100;
            tens_stage2     <= tens_stage1 * 8'd10;
            ones_stage2     <= ones_stage1;
        end
    end

    // Pipeline stage 3: Add hundreds and tens
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            binary_sum_stage1 <= 10'd0;
        end else begin
            binary_sum_stage1 <= hundreds_stage2 + tens_stage2;
        end
    end

    // Pipeline stage 4: Add ones to previous sum
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            binary_sum_stage2 <= 10'd0;
        end else begin
            binary_sum_stage2 <= binary_sum_stage1 + ones_stage2;
        end
    end

    // Write response logic
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            S_AXI_BVALID <= 1'b0;
            S_AXI_BRESP  <= 2'b00;
        end else begin
            if (S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WREADY && S_AXI_WVALID && ~S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b1;
                S_AXI_BRESP  <= 2'b00; // OKAY
            end else if (S_AXI_BVALID && S_AXI_BREADY) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end

    // Read address handshake
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            S_AXI_ARREADY <= 1'b0;
        end else begin
            if (!S_AXI_ARREADY && S_AXI_ARVALID) begin
                S_AXI_ARREADY <= 1'b1;
            end else begin
                S_AXI_ARREADY <= 1'b0;
            end
        end
    end

    // Read data pipeline stage 1
    reg [31:0] read_data_stage1;
    always @(*) begin
        case (S_AXI_ARADDR[ADDR_WIDTH-1:0])
            ADDR_BCD_INPUT:  read_data_stage1 = {20'd0, bcd_input_reg_stage3};
            ADDR_BIN_OUTPUT: read_data_stage1 = {22'd0, binary_sum_stage2};
            default:         read_data_stage1 = 32'd0;
        endcase
    end

    // Read data pipeline stage 2
    reg [31:0] read_data_stage2;
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            read_data_stage2 <= 32'd0;
        end else begin
            if (S_AXI_ARREADY && S_AXI_ARVALID && ~S_AXI_RVALID) begin
                read_data_stage2 <= read_data_stage1;
            end
        end
    end

    // Read response logic (with data pipeline)
    always @(posedge ACLK) begin
        if (!ARESETN) begin
            S_AXI_RVALID <= 1'b0;
            S_AXI_RRESP  <= 2'b00;
            S_AXI_RDATA  <= 32'd0;
        end else begin
            if (S_AXI_ARREADY && S_AXI_ARVALID && ~S_AXI_RVALID) begin
                S_AXI_RVALID <= 1'b1;
                S_AXI_RRESP  <= 2'b00; // OKAY
                S_AXI_RDATA  <= read_data_stage1;
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end else if (S_AXI_RVALID) begin
                S_AXI_RDATA <= read_data_stage2;
            end
        end
    end

endmodule