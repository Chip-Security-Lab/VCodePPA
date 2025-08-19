//SystemVerilog
`timescale 1ns/1ps
module i2c_multi_addr_slave_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input  wire               clk,
    input  wire               rst,

    // AXI4-Lite Slave Interface
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,

    input  wire [7:0]            s_axi_wdata,
    input  wire [0:0]            s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,

    output reg [1:0]             s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,

    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,

    output reg [7:0]             s_axi_rdata,
    output reg [1:0]             s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready
);

    // Internal registers for slave memory map
    reg [6:0] primary_addr_reg_stage1, primary_addr_reg_stage2;
    reg [6:0] secondary_addr_reg_stage1, secondary_addr_reg_stage2;
    reg [7:0] rx_data_reg_stage1, rx_data_reg_stage2;
    reg       rx_valid_reg_stage1, rx_valid_reg_stage2;

    // AXI4-Lite handshake state
    reg write_in_progress_stage1, write_in_progress_stage2;
    reg read_in_progress_stage1, read_in_progress_stage2;

    // Address decode
    localparam ADDR_PRIMARY   = 4'h0;
    localparam ADDR_SECONDARY = 4'h1;
    localparam ADDR_RX_DATA   = 4'h2;
    localparam ADDR_RX_VALID  = 4'h3;

    // Pipeline registers for address and data
    reg [ADDR_WIDTH-1:0] awaddr_stage1, awaddr_stage2;
    reg [7:0]            wdata_stage1, wdata_stage2;
    reg [0:0]            wstrb_stage1, wstrb_stage2;
    reg                  awvalid_stage1, awvalid_stage2;
    reg                  wvalid_stage1, wvalid_stage2;

    reg [ADDR_WIDTH-1:0] araddr_stage1, araddr_stage2;
    reg                  arvalid_stage1, arvalid_stage2;

    // Stage 1: Capture AW and W when ready and valid, assert ready signals
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            awaddr_stage1 <= {ADDR_WIDTH{1'b0}};
            wdata_stage1  <= 8'd0;
            wstrb_stage1  <= 1'b0;
            awvalid_stage1<= 1'b0;
            wvalid_stage1 <= 1'b0;
        end else begin
            // Write address channel
            if (~s_axi_awready && s_axi_awvalid && ~write_in_progress_stage1)
                s_axi_awready <= 1'b1;
            else
                s_axi_awready <= 1'b0;
            if (s_axi_awready && s_axi_awvalid && ~write_in_progress_stage1) begin
                awaddr_stage1  <= s_axi_awaddr;
                awvalid_stage1 <= 1'b1;
            end else begin
                awvalid_stage1 <= 1'b0;
            end

            // Write data channel
            if (~s_axi_wready && s_axi_wvalid && ~write_in_progress_stage1)
                s_axi_wready <= 1'b1;
            else
                s_axi_wready <= 1'b0;
            if (s_axi_wready && s_axi_wvalid && ~write_in_progress_stage1) begin
                wdata_stage1  <= s_axi_wdata;
                wstrb_stage1  <= s_axi_wstrb;
                wvalid_stage1 <= 1'b1;
            end else begin
                wvalid_stage1 <= 1'b0;
            end
        end
    end

    // Stage 2: Pipeline write address and data
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            awaddr_stage2  <= {ADDR_WIDTH{1'b0}};
            wdata_stage2   <= 8'd0;
            wstrb_stage2   <= 1'b0;
            awvalid_stage2 <= 1'b0;
            wvalid_stage2  <= 1'b0;
        end else begin
            awaddr_stage2  <= awaddr_stage1;
            wdata_stage2   <= wdata_stage1;
            wstrb_stage2   <= wstrb_stage1;
            awvalid_stage2 <= awvalid_stage1;
            wvalid_stage2  <= wvalid_stage1;
        end
    end

    // Stage 1: Capture AR when ready and valid, assert ready signal
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axi_arready   <= 1'b0;
            araddr_stage1   <= {ADDR_WIDTH{1'b0}};
            arvalid_stage1  <= 1'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid && ~read_in_progress_stage1)
                s_axi_arready <= 1'b1;
            else
                s_axi_arready <= 1'b0;
            if (s_axi_arready && s_axi_arvalid && ~read_in_progress_stage1) begin
                araddr_stage1  <= s_axi_araddr;
                arvalid_stage1 <= 1'b1;
            end else begin
                arvalid_stage1 <= 1'b0;
            end
        end
    end

    // Stage 2: Pipeline AR
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            araddr_stage2  <= {ADDR_WIDTH{1'b0}};
            arvalid_stage2 <= 1'b0;
        end else begin
            araddr_stage2  <= araddr_stage1;
            arvalid_stage2 <= arvalid_stage1;
        end
    end

    // Write Transaction Pipeline: Stage 1 (decode & latch), Stage 2 (commit)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_in_progress_stage1  <= 1'b0;
            write_in_progress_stage2  <= 1'b0;
            s_axi_bvalid              <= 1'b0;
            s_axi_bresp               <= 2'b00;
            primary_addr_reg_stage1   <= 7'd0;
            secondary_addr_reg_stage1 <= 7'd0;
            primary_addr_reg_stage2   <= 7'd0;
            secondary_addr_reg_stage2 <= 7'd0;
        end else begin
            // Stage 1: Detect write start
            if (awvalid_stage2 && wvalid_stage2 && ~write_in_progress_stage1) begin
                write_in_progress_stage1 <= 1'b1;
                case (awaddr_stage2)
                    ADDR_PRIMARY:   if (wstrb_stage2[0]) primary_addr_reg_stage1   <= wdata_stage2[6:0];
                    ADDR_SECONDARY: if (wstrb_stage2[0]) secondary_addr_reg_stage1 <= wdata_stage2[6:0];
                    default: ;
                endcase
            end else if (write_in_progress_stage2 && s_axi_bvalid && s_axi_bready) begin
                write_in_progress_stage1 <= 1'b0;
            end

            // Stage 2: Commit write and response
            primary_addr_reg_stage2   <= primary_addr_reg_stage1;
            secondary_addr_reg_stage2 <= secondary_addr_reg_stage1;

            if (write_in_progress_stage1 && ~write_in_progress_stage2) begin
                write_in_progress_stage2 <= 1'b1;
                s_axi_bvalid             <= 1'b1;
                s_axi_bresp              <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid             <= 1'b0;
                write_in_progress_stage2 <= 1'b0;
            end
        end
    end

    // Read Transaction Pipeline: Stage 1 (decode & latch), Stage 2 (output)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axi_rvalid             <= 1'b0;
            s_axi_rresp              <= 2'b00;
            s_axi_rdata              <= 8'd0;
            read_in_progress_stage1  <= 1'b0;
            read_in_progress_stage2  <= 1'b0;
        end else begin
            // Stage 1: Detect read start
            if (arvalid_stage2 && ~read_in_progress_stage1) begin
                read_in_progress_stage1 <= 1'b1;
            end else if (read_in_progress_stage2 && s_axi_rvalid && s_axi_rready) begin
                read_in_progress_stage1 <= 1'b0;
            end

            // Stage 2: Output data
            if (read_in_progress_stage1 && ~read_in_progress_stage2) begin
                read_in_progress_stage2 <= 1'b1;
                case (araddr_stage2)
                    ADDR_PRIMARY:   s_axi_rdata <= {1'b0, primary_addr_reg_stage2};
                    ADDR_SECONDARY: s_axi_rdata <= {1'b0, secondary_addr_reg_stage2};
                    ADDR_RX_DATA:   s_axi_rdata <= rx_data_reg_stage2;
                    ADDR_RX_VALID:  s_axi_rdata <= {7'd0, rx_valid_reg_stage2};
                    default:        s_axi_rdata <= 8'd0;
                endcase
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid         <= 1'b0;
                read_in_progress_stage2 <= 1'b0;
            end
        end
    end

    // Pipeline rx_data_reg and rx_valid_reg for read consistency
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_data_reg_stage2  <= 8'd0;
            rx_valid_reg_stage2 <= 1'b0;
        end else begin
            rx_data_reg_stage2  <= rx_data_reg_stage1;
            rx_valid_reg_stage2 <= rx_valid_reg_stage1;
        end
    end

    // Simulated I2C Slave Core (pipeline stages for timing closure)
    reg [2:0]  i2c_state_stage1, i2c_state_stage2;
    reg [7:0]  i2c_shift_reg_stage1, i2c_shift_reg_stage2;
    reg [3:0]  i2c_bit_idx_stage1, i2c_bit_idx_stage2;
    reg        i2c_addr_matched_stage1, i2c_addr_matched_stage2;
    reg        i2c_start_detected_stage1, i2c_start_detected_stage2;
    reg        scl_prev_stage1, scl_prev_stage2, sda_prev_stage1, sda_prev_stage2;
    wire       scl, sda;

    assign scl = 1'b0;
    assign sda = 1'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_prev_stage1 <= 1'b0;
            sda_prev_stage1 <= 1'b0;
            i2c_start_detected_stage1 <= 1'b0;
        end else begin
            scl_prev_stage1 <= scl;
            sda_prev_stage1 <= sda;
            i2c_start_detected_stage1 <= scl && scl_prev_stage1 && !sda && sda_prev_stage1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_prev_stage2 <= 1'b0;
            sda_prev_stage2 <= 1'b0;
            i2c_start_detected_stage2 <= 1'b0;
        end else begin
            scl_prev_stage2 <= scl_prev_stage1;
            sda_prev_stage2 <= sda_prev_stage1;
            i2c_start_detected_stage2 <= i2c_start_detected_stage1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i2c_state_stage1        <= 3'b000;
            i2c_shift_reg_stage1    <= 8'h00;
            i2c_bit_idx_stage1      <= 4'b0000;
            i2c_addr_matched_stage1 <= 1'b0;
            rx_valid_reg_stage1     <= 1'b0;
            rx_data_reg_stage1      <= 8'h00;
        end else begin
            case (i2c_state_stage1)
                3'b000: if (i2c_start_detected_stage2) begin
                    i2c_state_stage1     <= 3'b001;
                    i2c_bit_idx_stage1   <= 4'b0000;
                    i2c_shift_reg_stage1 <= 8'h00;
                end
                3'b001: if (i2c_bit_idx_stage1 == 4'd7) begin
                    i2c_addr_matched_stage1 <= (i2c_shift_reg_stage1[7:1] == primary_addr_reg_stage2) ||
                                               (i2c_shift_reg_stage1[7:1] == secondary_addr_reg_stage2);
                    i2c_state_stage1        <= ((i2c_shift_reg_stage1[7:1] == primary_addr_reg_stage2) ||
                                                (i2c_shift_reg_stage1[7:1] == secondary_addr_reg_stage2)) ? 3'b010 : 3'b000;
                end else begin
                    i2c_shift_reg_stage1 <= {i2c_shift_reg_stage1[6:0], 1'b0};
                    i2c_bit_idx_stage1   <= i2c_bit_idx_stage1 + 1;
                end
                3'b010: begin
                    i2c_state_stage1   <= 3'b011;
                    i2c_bit_idx_stage1 <= 4'b0000;
                end
                3'b011: if (i2c_bit_idx_stage1 == 4'd7) begin
                    rx_data_reg_stage1  <= i2c_shift_reg_stage1;
                    rx_valid_reg_stage1 <= 1'b1;
                    i2c_state_stage1    <= 3'b000;
                end else begin
                    i2c_shift_reg_stage1 <= {i2c_shift_reg_stage1[6:0], 1'b0};
                    i2c_bit_idx_stage1   <= i2c_bit_idx_stage1 + 1;
                end
                default: i2c_state_stage1 <= 3'b000;
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i2c_state_stage2        <= 3'b000;
            i2c_shift_reg_stage2    <= 8'h00;
            i2c_bit_idx_stage2      <= 4'b0000;
            i2c_addr_matched_stage2 <= 1'b0;
        end else begin
            i2c_state_stage2        <= i2c_state_stage1;
            i2c_shift_reg_stage2    <= i2c_shift_reg_stage1;
            i2c_bit_idx_stage2      <= i2c_bit_idx_stage1;
            i2c_addr_matched_stage2 <= i2c_addr_matched_stage1;
        end
    end

endmodule