//SystemVerilog
module UART_ByteSwap #(
    parameter SWAP_ENABLE = 1,
    parameter GROUP_SIZE = 2
)(
    input  wire         clk,        
    input  wire         rst_n,        // Active-low reset added for pipeline control
    input  wire         swap_en,    
    output reg  [7:0]   rx_swapped,
    input  wire [7:0]   tx_native,
    output reg  [7:0]   tx_data,    
    input  wire [7:0]   rx_data,    
    input  wire         rx_done     
);

// --- Pipeline Stage 1: Bit Reversal Preparation (Combinational) ---
wire [7:0] tx_data_reversed_stage1;
assign tx_data_reversed_stage1 = {tx_native[0], tx_native[1], tx_native[2], tx_native[3],
                                  tx_native[4], tx_native[5], tx_native[6], tx_native[7]};

wire [7:0] rx_data_reversed_stage1;
assign rx_data_reversed_stage1 = {rx_data[0], rx_data[1], rx_data[2], rx_data[3],
                                  rx_data[4], rx_data[5], rx_data[6], rx_data[7]};

// --- Pipeline Stage 1: Control Signal Latching ---
reg swap_en_stage1;
reg rx_done_stage1;
reg [7:0] rx_data_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        swap_en_stage1 <= 1'b0;
        rx_done_stage1 <= 1'b0;
        rx_data_stage1 <= 8'b0;
    end else begin
        swap_en_stage1 <= swap_en;
        rx_done_stage1 <= rx_done;
        rx_data_stage1 <= rx_data;
    end
end

// --- Pipeline Stage 2: Sending Data (tx) Pipeline Register ---
reg [7:0] tx_data_stage2;
reg swap_en_stage2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_data_stage2 <= 8'b0;
        swap_en_stage2 <= 1'b0;
    end else begin
        tx_data_stage2 <= (SWAP_ENABLE && swap_en) ? tx_data_reversed_stage1 : tx_native;
        swap_en_stage2 <= swap_en_stage1;
    end
end

always @(*) begin
    tx_data = tx_data_stage2;
end

// --- Pipeline Stage 2: Receiving Data (rx) Pipeline Register ---
generate
    if (GROUP_SIZE > 1) begin : group_swap_pipeline
        // Stage 2 registers
        reg [7:0] rx_data_reversed_stage2;
        reg [7:0] rx_data_stage2;
        reg       swap_en_stage2_rx;
        reg       rx_done_stage2;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                rx_data_reversed_stage2 <= 8'b0;
                rx_data_stage2 <= 8'b0;
                swap_en_stage2_rx <= 1'b0;
                rx_done_stage2 <= 1'b0;
            end else begin
                rx_data_reversed_stage2 <= rx_data_reversed_stage1;
                rx_data_stage2 <= rx_data_stage1;
                swap_en_stage2_rx <= swap_en_stage1;
                rx_done_stage2 <= rx_done_stage1;
            end
        end

        // Stage 3: Buffer write and output
        reg [7:0] rx_buffer_stage3 [0:GROUP_SIZE-1];
        integer idx_stage3;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                for (idx_stage3 = 0; idx_stage3 < GROUP_SIZE; idx_stage3 = idx_stage3 + 1) begin
                    rx_buffer_stage3[idx_stage3] <= 8'b0;
                end
                rx_swapped <= 8'b0;
            end else if (rx_done_stage2) begin
                if (swap_en_stage2_rx) begin
                    for (idx_stage3 = 0; idx_stage3 < GROUP_SIZE; idx_stage3 = idx_stage3 + 1) begin
                        rx_buffer_stage3[idx_stage3] <= rx_data_reversed_stage2;
                    end
                end else begin
                    for (idx_stage3 = 0; idx_stage3 < GROUP_SIZE; idx_stage3 = idx_stage3 + 1) begin
                        rx_buffer_stage3[idx_stage3] <= rx_data_stage2;
                    end
                end
                rx_swapped <= rx_buffer_stage3[0];
            end
        end
    end else begin : single_swap_pipeline
        // Stage 2 registers
        reg [7:0] rx_data_reversed_stage2;
        reg [7:0] rx_data_stage2;
        reg       swap_en_stage2_rx;
        reg       rx_done_stage2;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                rx_data_reversed_stage2 <= 8'b0;
                rx_data_stage2 <= 8'b0;
                swap_en_stage2_rx <= 1'b0;
                rx_done_stage2 <= 1'b0;
            end else begin
                rx_data_reversed_stage2 <= rx_data_reversed_stage1;
                rx_data_stage2 <= rx_data_stage1;
                swap_en_stage2_rx <= swap_en_stage1;
                rx_done_stage2 <= rx_done_stage1;
            end
        end

        // Stage 3: Output
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                rx_swapped <= 8'b0;
            end else if (rx_done_stage2) begin
                rx_swapped <= (swap_en_stage2_rx) ? rx_data_reversed_stage2 : rx_data_stage2;
            end
        end
    end
endgenerate

endmodule