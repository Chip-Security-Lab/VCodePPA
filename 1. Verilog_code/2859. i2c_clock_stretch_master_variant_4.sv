//SystemVerilog
`timescale 1ns / 1ps

module i2c_clock_stretch_master_axi4lite #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input  wire                  S_AXI_ACLK,
    input  wire                  S_AXI_ARESETN,
    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire                  S_AXI_AWVALID,
    output reg                   S_AXI_AWREADY,
    // AXI4-Lite Write Data Channel
    input  wire [DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [(DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                  S_AXI_WVALID,
    output reg                   S_AXI_WREADY,
    // AXI4-Lite Write Response Channel
    output reg  [1:0]            S_AXI_BRESP,
    output reg                   S_AXI_BVALID,
    input  wire                  S_AXI_BREADY,
    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire                  S_AXI_ARVALID,
    output reg                   S_AXI_ARREADY,
    // AXI4-Lite Read Data Channel
    output reg [DATA_WIDTH-1:0]  S_AXI_RDATA,
    output reg [1:0]             S_AXI_RRESP,
    output reg                   S_AXI_RVALID,
    input  wire                  S_AXI_RREADY,
    // I2C signals
    inout  wire                  sda,
    inout  wire                  scl
);

    // AXI4-Lite Address Map
    localparam ADDR_TARGET_ADDRESS = 4'h0;
    localparam ADDR_READ_NOTWRITE  = 4'h4;
    localparam ADDR_WRITE_BYTE     = 4'h8;
    localparam ADDR_READ_BYTE      = 4'hC;
    localparam ADDR_CONTROL        = 4'h10;
    localparam ADDR_STATUS         = 4'h14;

    // AXI4-Lite Registers
    reg [6:0] target_address_reg_stage1, target_address_reg_stage2;
    reg       read_notwrite_reg_stage1, read_notwrite_reg_stage2;
    reg [7:0] write_byte_reg_stage1, write_byte_reg_stage2;
    reg       start_transfer_reg_stage1, start_transfer_reg_stage2;
    reg [7:0] read_byte_reg_stage1, read_byte_reg_stage2;
    reg       transfer_done_reg_stage1, transfer_done_reg_stage2;
    reg       error_reg_stage1, error_reg_stage2;

    // I2C Internal signals
    reg scl_enable_stage1, scl_enable_stage2;
    reg sda_enable_stage1, sda_enable_stage2;
    reg sda_out_stage1, sda_out_stage2;
    reg [3:0] FSM_stage1, FSM_stage2;
    reg [3:0] bit_index_stage1, bit_index_stage2;

    wire scl_stretched_stage1 = !scl && !scl_enable_stage1;
    wire scl_stretched_stage2 = !scl && !scl_enable_stage2;

    // Pipeline valid signals
    reg aw_valid_stage1, aw_valid_stage2;
    reg w_valid_stage1, w_valid_stage2;
    reg b_valid_stage1, b_valid_stage2;
    reg ar_valid_stage1, ar_valid_stage2;
    reg r_valid_stage1, r_valid_stage2;

    // Pipeline flush signals
    reg flush_stage1, flush_stage2;

    // AXI4-Lite Write Address/Data Pipeline Stage 1
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY         <= 1'b0;
            S_AXI_WREADY          <= 1'b0;
            aw_valid_stage1       <= 1'b0;
            w_valid_stage1        <= 1'b0;
            flush_stage1          <= 1'b0;
        end else begin
            if (flush_stage1) begin
                S_AXI_AWREADY     <= 1'b0;
                S_AXI_WREADY      <= 1'b0;
                aw_valid_stage1   <= 1'b0;
                w_valid_stage1    <= 1'b0;
                flush_stage1      <= 1'b0;
            end else if (~S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WVALID) begin
                S_AXI_AWREADY     <= 1'b1;
                S_AXI_WREADY      <= 1'b1;
                aw_valid_stage1   <= S_AXI_AWVALID;
                w_valid_stage1    <= S_AXI_WVALID;
            end else begin
                S_AXI_AWREADY     <= 1'b0;
                S_AXI_WREADY      <= 1'b0;
                aw_valid_stage1   <= 1'b0;
                w_valid_stage1    <= 1'b0;
            end
        end
    end

    // AXI4-Lite Write Address/Data Pipeline Stage 2
    reg [ADDR_WIDTH-1:0] awaddr_stage1, awaddr_stage2;
    reg [DATA_WIDTH-1:0] wdata_stage1, wdata_stage2;
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            awaddr_stage1          <= {ADDR_WIDTH{1'b0}};
            wdata_stage1           <= {DATA_WIDTH{1'b0}};
            aw_valid_stage2        <= 1'b0;
            w_valid_stage2         <= 1'b0;
            awaddr_stage2          <= {ADDR_WIDTH{1'b0}};
            wdata_stage2           <= {DATA_WIDTH{1'b0}};
        end else begin
            if (S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WREADY && S_AXI_WVALID) begin
                awaddr_stage1      <= S_AXI_AWADDR;
                wdata_stage1       <= S_AXI_WDATA;
                aw_valid_stage2    <= aw_valid_stage1;
                w_valid_stage2     <= w_valid_stage1;
                awaddr_stage2      <= awaddr_stage1;
                wdata_stage2       <= wdata_stage1;
            end else begin
                aw_valid_stage2    <= 1'b0;
                w_valid_stage2     <= 1'b0;
            end
        end
    end

    // AXI4-Lite Write FSM Pipeline Stage 2 (Register write)
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_BVALID                <= 1'b0;
            S_AXI_BRESP                 <= 2'b00;
            b_valid_stage1              <= 1'b0;
            b_valid_stage2              <= 1'b0;
            target_address_reg_stage1   <= 7'd0;
            read_notwrite_reg_stage1    <= 1'b0;
            write_byte_reg_stage1       <= 8'd0;
            start_transfer_reg_stage1   <= 1'b0;
        end else begin
            b_valid_stage2 <= 1'b0;
            if (aw_valid_stage2 && w_valid_stage2) begin
                case (awaddr_stage2)
                    ADDR_TARGET_ADDRESS: target_address_reg_stage1 <= wdata_stage2[6:0];
                    ADDR_READ_NOTWRITE:  read_notwrite_reg_stage1  <= wdata_stage2[0];
                    ADDR_WRITE_BYTE:     write_byte_reg_stage1     <= wdata_stage2[7:0];
                    ADDR_CONTROL:        start_transfer_reg_stage1 <= wdata_stage2[0];
                    default: ;
                endcase
                S_AXI_BVALID   <= 1'b1;
                S_AXI_BRESP    <= 2'b00;
                b_valid_stage1 <= 1'b1;
                b_valid_stage2 <= b_valid_stage1;
            end else if (S_AXI_BREADY && S_AXI_BVALID) begin
                S_AXI_BVALID   <= 1'b0;
                b_valid_stage1 <= 1'b0;
            end
        end
    end

    // AXI4-Lite Register Write Pipeline Stage 3 (finalize)
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            target_address_reg_stage2 <= 7'd0;
            read_notwrite_reg_stage2  <= 1'b0;
            write_byte_reg_stage2     <= 8'd0;
            start_transfer_reg_stage2 <= 1'b0;
        end else begin
            target_address_reg_stage2 <= target_address_reg_stage1;
            read_notwrite_reg_stage2  <= read_notwrite_reg_stage1;
            write_byte_reg_stage2     <= write_byte_reg_stage1;
            start_transfer_reg_stage2 <= start_transfer_reg_stage1;
        end
    end

    // AXI4-Lite Read Address Pipeline Stage 1
    reg [ADDR_WIDTH-1:0] araddr_stage1, araddr_stage2;
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY      <= 1'b0;
            ar_valid_stage1    <= 1'b0;
            araddr_stage1      <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (~S_AXI_ARREADY && S_AXI_ARVALID) begin
                S_AXI_ARREADY  <= 1'b1;
                ar_valid_stage1<= 1'b1;
                araddr_stage1  <= S_AXI_ARADDR;
            end else begin
                S_AXI_ARREADY  <= 1'b0;
                ar_valid_stage1<= 1'b0;
            end
        end
    end

    // AXI4-Lite Read Address Pipeline Stage 2
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            ar_valid_stage2    <= 1'b0;
            araddr_stage2      <= {ADDR_WIDTH{1'b0}};
        end else begin
            ar_valid_stage2    <= ar_valid_stage1;
            araddr_stage2      <= araddr_stage1;
        end
    end

    // AXI4-Lite Read Data Pipeline Stage 2
    reg [DATA_WIDTH-1:0] rdata_stage1, rdata_stage2;
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_RVALID      <= 1'b0;
            S_AXI_RRESP       <= 2'b00;
            S_AXI_RDATA       <= {DATA_WIDTH{1'b0}};
            r_valid_stage1    <= 1'b0;
            r_valid_stage2    <= 1'b0;
            rdata_stage1      <= {DATA_WIDTH{1'b0}};
            rdata_stage2      <= {DATA_WIDTH{1'b0}};
        end else begin
            if (ar_valid_stage2) begin
                case (araddr_stage2)
                    ADDR_TARGET_ADDRESS: rdata_stage1 <= {1'b0, target_address_reg_stage2};
                    ADDR_READ_NOTWRITE:  rdata_stage1 <= {7'b0, read_notwrite_reg_stage2};
                    ADDR_WRITE_BYTE:     rdata_stage1 <= write_byte_reg_stage2;
                    ADDR_READ_BYTE:      rdata_stage1 <= read_byte_reg_stage2;
                    ADDR_CONTROL:        rdata_stage1 <= {7'b0, start_transfer_reg_stage2};
                    ADDR_STATUS:         rdata_stage1 <= {5'b0, error_reg_stage2, transfer_done_reg_stage2, 1'b0};
                    default:             rdata_stage1 <= {DATA_WIDTH{1'b0}};
                endcase
                S_AXI_RVALID   <= 1'b1;
                S_AXI_RRESP    <= 2'b00;
                r_valid_stage1 <= 1'b1;
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID   <= 1'b0;
                r_valid_stage1 <= 1'b0;
            end else begin
                r_valid_stage1 <= 1'b0;
            end

            r_valid_stage2 <= r_valid_stage1;
            rdata_stage2   <= rdata_stage1;
            if (r_valid_stage2) begin
                S_AXI_RDATA <= rdata_stage2;
            end
        end
    end

    // I2C FSM Pipeline Stage 1
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            FSM_stage1               <= 4'd0;
            scl_enable_stage1        <= 1'b0;
            sda_enable_stage1        <= 1'b0;
            sda_out_stage1           <= 1'b1;
            bit_index_stage1         <= 4'd0;
            read_byte_reg_stage1     <= 8'd0;
            transfer_done_reg_stage1 <= 1'b0;
            error_reg_stage1         <= 1'b0;
            start_transfer_reg_stage1<= 1'b0;
        end else begin
            if (scl_stretched_stage1 && FSM_stage1 != 4'd0) begin
                FSM_stage1 <= FSM_stage1; // Hold state during stretching
            end else begin
                case (FSM_stage1)
                    4'd0: begin
                        transfer_done_reg_stage1 <= 1'b0;
                        error_reg_stage1        <= 1'b0;
                        if (start_transfer_reg_stage2) begin
                            FSM_stage1             <= 4'd1;
                            start_transfer_reg_stage1 <= 1'b0;
                        end
                    end
                    // ... (Insert the original state machine implementation here, pipelined as needed) ...
                    default: FSM_stage1 <= 4'd0;
                endcase
            end
        end
    end

    // I2C FSM Pipeline Stage 2
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            FSM_stage2               <= 4'd0;
            scl_enable_stage2        <= 1'b0;
            sda_enable_stage2        <= 1'b0;
            sda_out_stage2           <= 1'b1;
            bit_index_stage2         <= 4'd0;
            read_byte_reg_stage2     <= 8'd0;
            transfer_done_reg_stage2 <= 1'b0;
            error_reg_stage2         <= 1'b0;
            start_transfer_reg_stage2<= 1'b0;
        end else begin
            FSM_stage2               <= FSM_stage1;
            scl_enable_stage2        <= scl_enable_stage1;
            sda_enable_stage2        <= sda_enable_stage1;
            sda_out_stage2           <= sda_out_stage1;
            bit_index_stage2         <= bit_index_stage1;
            read_byte_reg_stage2     <= read_byte_reg_stage1;
            transfer_done_reg_stage2 <= transfer_done_reg_stage1;
            error_reg_stage2         <= error_reg_stage1;
            start_transfer_reg_stage2<= start_transfer_reg_stage1;
        end
    end

    assign scl = scl_enable_stage2 ? 1'b0 : 1'bz;
    assign sda = sda_enable_stage2 ? sda_out_stage2 : 1'bz;

endmodule