//SystemVerilog
// Top-level module: UART_ByteSwap_AXI4Lite
// Function: Hierarchical byte swap for UART with parameterizable swap and group size, AXI4-Lite slave interface.

module UART_ByteSwap_AXI4Lite #(
    parameter SWAP_ENABLE = 1,
    parameter GROUP_SIZE = 2
)(
    // AXI4-Lite clock and reset
    input  wire         s_axi_aclk,
    input  wire         s_axi_aresetn,

    // AXI4-Lite Write Address Channel
    input  wire [3:0]   s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [7:0]   s_axi_wdata,
    input  wire [0:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]   s_axi_bresp,
    output reg          s_axi_bvalid,
    input  wire         s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [3:0]   s_axi_araddr,
    input  wire         s_axi_arvalid,
    output reg          s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg  [7:0]   s_axi_rdata,
    output reg  [1:0]   s_axi_rresp,
    output reg          s_axi_rvalid,
    input  wire         s_axi_rready
);

    // Internal Registers mapped to AXI4-Lite
    // Address Map:
    // 0x00: Control (bit 0: swap_en)
    // 0x04: TX Native Data (write only)
    // 0x08: RX Swapped Data (read only)
    // 0x0C: RX Done (read only, auto-clear)
    // 0x10: RX Data (write only, triggers RX)
    // 0x14: TX Data (read only)

    // Control Register
    reg swap_en_reg;

    // TX Data Registers
    reg [7:0] tx_native_reg;
    wire [7:0] tx_data_wire;

    // RX Data Registers
    reg [7:0] rx_data_reg;
    reg       rx_done_reg;
    wire [7:0] rx_swapped_wire;

    // RX Done auto-clear logic
    reg rx_done_read;

    // Internal handshake flags
    reg aw_en;
    reg ar_en;

    // Write FSM
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            aw_en         <= 1'b1;
        end else begin
            // Write Address Ready
            if (!s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end

            // Write Response
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && aw_en) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
                aw_en <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                aw_en <= 1'b1;
            end
        end
    end

    // Write Register Logic
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            swap_en_reg    <= 1'b0;
            tx_native_reg  <= 8'b0;
            rx_data_reg    <= 8'b0;
            rx_done_reg    <= 1'b0;
        end else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
                case (s_axi_awaddr[3:0])
                    4'h0: begin
                        if (s_axi_wstrb[0]) swap_en_reg <= s_axi_wdata[0];
                    end
                    4'h4: begin
                        if (s_axi_wstrb[0]) tx_native_reg <= s_axi_wdata;
                    end
                    4'h10: begin
                        if (s_axi_wstrb[0]) begin
                            rx_data_reg <= s_axi_wdata;
                            rx_done_reg <= 1'b1;
                        end
                    end
                    default: ;
                endcase
            end
            // RX Done auto-clear on read
            if (rx_done_read)
                rx_done_reg <= 1'b0;
        end
    end

    // Read FSM
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            ar_en         <= 1'b1;
            s_axi_rdata   <= 8'b0;
            rx_done_read  <= 1'b0;
        end else begin
            // Read Address Ready
            if (!s_axi_arready && s_axi_arvalid && ar_en) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            // Read Data Valid
            if (s_axi_arready && s_axi_arvalid && ar_en) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
                case (s_axi_araddr[3:0])
                    4'h0:  s_axi_rdata <= {7'b0, swap_en_reg};
                    4'h8:  s_axi_rdata <= rx_swapped_wire;
                    4'hC:  s_axi_rdata <= {7'b0, rx_done_reg};
                    4'h14: s_axi_rdata <= tx_data_wire;
                    default: s_axi_rdata <= 8'b0;
                endcase
                rx_done_read <= (s_axi_araddr[3:0] == 4'hC) ? 1'b1 : 1'b0;
                ar_en <= 1'b0;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
                ar_en <= 1'b1;
                rx_done_read <= 1'b0;
            end
        end
    end

    // Instantiate TX Byte Swap Processing
    UART_ByteSwap_Tx #(
        .SWAP_ENABLE(SWAP_ENABLE)
    ) u_tx_swap (
        .swap_en   (swap_en_reg),
        .tx_native (tx_native_reg),
        .tx_data   (tx_data_wire)
    );

    // Instantiate RX Byte Swap Processing
    generate
        if (GROUP_SIZE > 1) begin : gen_group_swap_axi
            UART_ByteSwap_RxGroup_AXI4Lite #(
                .GROUP_SIZE(GROUP_SIZE)
            ) u_rx_group_swap (
                .clk        (s_axi_aclk),
                .swap_en    (swap_en_reg),
                .rx_data    (rx_data_reg),
                .rx_done    (rx_done_reg),
                .rx_swapped (rx_swapped_wire)
            );
        end else begin : gen_single_swap_axi
            UART_ByteSwap_RxSingle_AXI4Lite u_rx_single_swap (
                .clk        (s_axi_aclk),
                .swap_en    (swap_en_reg),
                .rx_data    (rx_data_reg),
                .rx_done    (rx_done_reg),
                .rx_swapped (rx_swapped_wire)
            );
        end
    endgenerate

endmodule

// -----------------------------------------------------------------------------
// Byte Swap Function Module (Reusable)
// -----------------------------------------------------------------------------
module UART_ByteSwap_ByteReverse(
    input  wire [7:0] data_in,
    output wire [7:0] data_out
);
    // Function: reverses the order of bits in a byte
    assign data_out = {data_in[0], data_in[1], data_in[2], data_in[3], data_in[4], data_in[5], data_in[6], data_in[7]};
endmodule

// -----------------------------------------------------------------------------
// TX Byte Swap Processing Module
// -----------------------------------------------------------------------------
module UART_ByteSwap_Tx #(
    parameter SWAP_ENABLE = 1
)(
    input  wire        swap_en,
    input  wire [7:0]  tx_native,
    output wire [7:0]  tx_data
);
    wire [7:0] swapped_tx;

    UART_ByteSwap_ByteReverse u_tx_reverse (
        .data_in  (tx_native),
        .data_out (swapped_tx)
    );

    assign tx_data = (SWAP_ENABLE && swap_en) ? swapped_tx : tx_native;
endmodule

// -----------------------------------------------------------------------------
// RX Group Swap Processing Module for AXI4-Lite
// Handles swapping for GROUP_SIZE > 1
// -----------------------------------------------------------------------------
module UART_ByteSwap_RxGroup_AXI4Lite #(
    parameter GROUP_SIZE = 2
)(
    input  wire         clk,
    input  wire         swap_en,
    input  wire [7:0]   rx_data,
    input  wire         rx_done,
    output reg  [7:0]   rx_swapped
);
    reg [7:0] rx_buffer [0:GROUP_SIZE-1];
    reg [7:0] swap_buffer [0:GROUP_SIZE-1];
    integer i;

    reg [$clog2(GROUP_SIZE):0] byte_cnt;

    wire [7:0] rx_data_swapped;
    UART_ByteSwap_ByteReverse u_rx_reverse (
        .data_in  (rx_data),
        .data_out (rx_data_swapped)
    );

    always @(posedge clk) begin
        if (rx_done) begin
            if (swap_en) begin
                swap_buffer[byte_cnt] <= rx_data_swapped;
            end else begin
                swap_buffer[byte_cnt] <= rx_data;
            end

            if (byte_cnt == (GROUP_SIZE-1)) begin
                for (i = 0; i < GROUP_SIZE; i = i + 1) begin
                    rx_buffer[i] <= swap_buffer[GROUP_SIZE-1-i];
                end
                rx_swapped <= swap_buffer[GROUP_SIZE-1];
                byte_cnt <= 0;
            end else begin
                byte_cnt <= byte_cnt + 1;
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// RX Single Byte Swap Processing Module for AXI4-Lite
// Handles swapping for GROUP_SIZE == 1
// -----------------------------------------------------------------------------
module UART_ByteSwap_RxSingle_AXI4Lite(
    input  wire        clk,
    input  wire        swap_en,
    input  wire [7:0]  rx_data,
    input  wire        rx_done,
    output reg  [7:0]  rx_swapped
);
    wire [7:0] rx_data_swapped;

    UART_ByteSwap_ByteReverse u_rx_reverse (
        .data_in  (rx_data),
        .data_out (rx_data_swapped)
    );

    always @(posedge clk) begin
        if (rx_done)
            rx_swapped <= swap_en ? rx_data_swapped : rx_data;
    end
endmodule