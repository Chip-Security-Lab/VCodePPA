//SystemVerilog
module UART_ByteSwap #(
    parameter SWAP_ENABLE = 1,
    parameter GROUP_SIZE = 2
)(
    input  wire         clk,        
    input  wire         swap_en,    
    output reg  [7:0]   rx_swapped,
    input  wire [7:0]   tx_native,
    output reg  [7:0]   tx_data,    
    input  wire [7:0]   rx_data,    
    input  wire         rx_done     
);

// ---------- Pipeline Stage 1: Swap Enable Buffering ----------
reg swap_en_stage1;
reg swap_en_stage2;
reg swap_en_stage3;

always @(posedge clk) begin
    swap_en_stage1 <= swap_en;
    swap_en_stage2 <= swap_en_stage1;
    swap_en_stage3 <= swap_en_stage2;
end

// ---------- Pipeline Stage 2: TX Data Swap Preparation ----------
reg [7:0] tx_native_stage1;
reg [7:0] tx_native_stage2;
reg [7:0] tx_swapped_stage2;

always @(posedge clk) begin
    tx_native_stage1 <= tx_native;
end

// ---------- Pipeline Stage 3: TX Swap Operation (Bit Reversal) ----------
reg [7:0] tx_swapped_stage3;

always @(posedge clk) begin
    if (SWAP_ENABLE && swap_en_stage2) begin
        tx_native_stage2 <= tx_native_stage1;
        tx_swapped_stage2 <= {tx_native_stage1[0], tx_native_stage1[1], tx_native_stage1[2], tx_native_stage1[3],
                              tx_native_stage1[4], tx_native_stage1[5], tx_native_stage1[6], tx_native_stage1[7]};
        // Bit reversal is split into two stages for pipeline
        tx_swapped_stage3[7] <= tx_native_stage1[0];
        tx_swapped_stage3[6] <= tx_native_stage1[1];
        tx_swapped_stage3[5] <= tx_native_stage1[2];
        tx_swapped_stage3[4] <= tx_native_stage1[3];
        tx_swapped_stage3[3] <= tx_native_stage1[4];
        tx_swapped_stage3[2] <= tx_native_stage1[5];
        tx_swapped_stage3[1] <= tx_native_stage1[6];
        tx_swapped_stage3[0] <= tx_native_stage1[7];
    end else begin
        tx_native_stage2 <= tx_native_stage1;
        tx_swapped_stage2 <= tx_native_stage1;
        tx_swapped_stage3 <= tx_native_stage1;
    end
end

// ---------- Pipeline Stage 4: TX Data Output ----------
always @(posedge clk) begin
    if (SWAP_ENABLE && swap_en_stage3)
        tx_data <= tx_swapped_stage3;
    else
        tx_data <= tx_native_stage2;
end

// ---------- RX Side Processing ----------
generate
    if (GROUP_SIZE > 1) begin : group_swap
        // ---------- Pipeline Stage 1: Swap Enable Buffering ----------
        reg swap_en_rx_stage1;
        reg swap_en_rx_stage2;
        reg swap_en_rx_stage3;
        always @(posedge clk) begin
            swap_en_rx_stage1 <= swap_en;
            swap_en_rx_stage2 <= swap_en_rx_stage1;
            swap_en_rx_stage3 <= swap_en_rx_stage2;
        end

        // ---------- Pipeline Stage 2: RX Data Buffering ----------
        reg [7:0] rx_data_stage1;
        reg [7:0] rx_data_stage2;
        always @(posedge clk) begin
            rx_data_stage1 <= rx_data;
            rx_data_stage2 <= rx_data_stage1;
        end

        // ---------- Pipeline Stage 3: Swap Buffering ----------
        reg [7:0] rx_buffer_stage3 [0:GROUP_SIZE-1];
        reg [7:0] swap_buffer_stage3 [0:GROUP_SIZE-1];
        integer i;
        always @(posedge clk) begin
            for (i=0;i<GROUP_SIZE;i=i+1) begin
                swap_buffer_stage3[i] <= rx_data_stage2; // Placeholder for group data assignment
            end
        end

        // ---------- Pipeline Stage 4: Group Swap Operation ----------
        reg [7:0] rx_buffer_stage4 [0:GROUP_SIZE-1];
        always @(posedge clk) begin
            if (rx_done) begin
                for (i=0;i<GROUP_SIZE;i=i+1) begin
                    rx_buffer_stage4[i] <= swap_buffer_stage3[GROUP_SIZE-1-i];
                end
            end
        end

        // ---------- Pipeline Stage 5: Output Assignment ----------
        always @(posedge clk) begin
            if (rx_done) begin
                rx_swapped <= rx_buffer_stage4[0];
            end
        end

    end else begin : single_swap
        // ---------- Pipeline Stage 1: Swap Enable Buffering ----------
        reg swap_en_rx_stage1;
        reg swap_en_rx_stage2;
        reg swap_en_rx_stage3;
        always @(posedge clk) begin
            swap_en_rx_stage1 <= swap_en;
            swap_en_rx_stage2 <= swap_en_rx_stage1;
            swap_en_rx_stage3 <= swap_en_rx_stage2;
        end

        // ---------- Pipeline Stage 2: RX Data Buffering ----------
        reg [7:0] rx_data_stage1;
        reg [7:0] rx_data_stage2;
        always @(posedge clk) begin
            rx_data_stage1 <= rx_data;
            rx_data_stage2 <= rx_data_stage1;
        end

        // ---------- Pipeline Stage 3: RX Data Swap ----------
        reg [7:0] rx_swapped_stage3;
        always @(posedge clk) begin
            if (swap_en_rx_stage2) begin
                rx_swapped_stage3[7] <= rx_data_stage2[0];
                rx_swapped_stage3[6] <= rx_data_stage2[1];
                rx_swapped_stage3[5] <= rx_data_stage2[2];
                rx_swapped_stage3[4] <= rx_data_stage2[3];
                rx_swapped_stage3[3] <= rx_data_stage2[4];
                rx_swapped_stage3[2] <= rx_data_stage2[5];
                rx_swapped_stage3[1] <= rx_data_stage2[6];
                rx_swapped_stage3[0] <= rx_data_stage2[7];
            end else begin
                rx_swapped_stage3 <= rx_data_stage2;
            end
        end

        // ---------- Pipeline Stage 4: RX Output Assignment ----------
        always @(posedge clk) begin
            if (rx_done)
                rx_swapped <= rx_swapped_stage3;
        end
    end
endgenerate

endmodule