//SystemVerilog
module spi_master_dma(
    input  wire         clk,
    input  wire         rst_n,
    // DMA interface
    input  wire [7:0]   dma_data_in,
    input  wire         dma_valid_in,
    output reg          dma_ready_out,
    output reg  [7:0]   dma_data_out,
    output reg          dma_valid_out,
    input  wire         dma_ready_in,
    // Control signals
    input  wire         transfer_start,
    input  wire [15:0]  transfer_length, // bytes
    output reg          transfer_busy,
    output reg          transfer_done,
    // SPI interface
    output reg          sclk,
    output reg          cs_n,
    output wire         mosi,
    input  wire         miso
);

    localparam IDLE        = 3'd0,
               LOAD        = 3'd1,
               SHIFT_OUT   = 3'd2,
               SHIFT_IN    = 3'd3,
               STORE       = 3'd4,
               FINISH      = 3'd5;

    reg [2:0]   state, next_state;
    reg [7:0]   tx_shift, tx_shift_next;
    reg [7:0]   rx_shift, rx_shift_next;
    reg [2:0]   bit_count, bit_count_next;
    reg [15:0]  byte_count, byte_count_next;

    // Forward-retimed DMA input register
    reg [7:0]   dma_data_in_reg;
    reg         dma_valid_in_reg;

    wire        load_condition;
    wire        finish_condition;
    wire        idle_condition;
    wire        shift_out_condition;
    wire        shift_in_condition;
    wire        store_condition;

    assign mosi = tx_shift[7];

    // Precompute conditions to balance logic and reduce depth
    assign idle_condition      = (state == IDLE)  && transfer_start;
    assign load_condition      = (state == LOAD)  && (dma_valid_in_reg && dma_ready_out);
    assign finish_condition    = (state == FINISH);
    assign shift_out_condition = 1'b0;
    assign shift_in_condition  = 1'b0;
    assign store_condition     = 1'b0;

    // Forward-retimed input register: moves register after combinational logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_data_in_reg  <= 8'd0;
            dma_valid_in_reg <= 1'b0;
        end else begin
            // Register only when in LOAD state and ready to accept data
            if ((state == LOAD) && dma_valid_in && dma_ready_out) begin
                dma_data_in_reg  <= dma_data_in;
                dma_valid_in_reg <= dma_valid_in;
            end else begin
                dma_data_in_reg  <= dma_data_in_reg;
                dma_valid_in_reg <= 1'b0;
            end
        end
    end

    // Next state logic and path balancing
    always @* begin
        // Default assignments
        next_state        = state;
        tx_shift_next     = tx_shift;
        rx_shift_next     = rx_shift;
        bit_count_next    = bit_count;
        byte_count_next   = byte_count;

        case (state)
            IDLE: begin
                if (transfer_start) begin
                    next_state      = LOAD;
                    byte_count_next = transfer_length;
                end
            end
            LOAD: begin
                if (dma_valid_in_reg && dma_ready_out) begin
                    next_state      = SHIFT_OUT;
                    tx_shift_next   = dma_data_in_reg;
                    bit_count_next  = 3'd7;
                end
            end
            FINISH: begin
                next_state = IDLE;
            end
            default: next_state = state;
        endcase
    end

    // Output and register update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= IDLE;
            tx_shift        <= 8'h00;
            rx_shift        <= 8'h00;
            bit_count       <= 3'd0;
            byte_count      <= 16'd0;
            cs_n            <= 1'b1;
            sclk            <= 1'b0;
            transfer_busy   <= 1'b0;
            transfer_done   <= 1'b0;
            dma_ready_out   <= 1'b0;
            dma_valid_out   <= 1'b0;
            dma_data_out    <= 8'h00;
        end else begin
            state        <= next_state;
            tx_shift     <= tx_shift_next;
            rx_shift     <= rx_shift_next;
            bit_count    <= bit_count_next;
            byte_count   <= byte_count_next;

            // Output logic path balancing
            // Default assignments
            cs_n            <= cs_n;
            sclk            <= sclk;
            transfer_busy   <= transfer_busy;
            transfer_done   <= transfer_done;
            dma_ready_out   <= dma_ready_out;
            dma_valid_out   <= dma_valid_out;
            dma_data_out    <= dma_data_out;

            // Balanced logic for outputs
            if (idle_condition) begin
                transfer_busy   <= 1'b1;
                cs_n            <= 1'b0;
                dma_ready_out   <= 1'b1;
                transfer_done   <= 1'b0;
                dma_valid_out   <= 1'b0;
            end else if (load_condition) begin
                dma_ready_out   <= 1'b0;
            end else if (finish_condition) begin
                cs_n            <= 1'b1;
                transfer_busy   <= 1'b0;
                transfer_done   <= 1'b1;
            end else begin
                // Hold values in other states
            end
        end
    end

endmodule