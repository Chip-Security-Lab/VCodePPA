//SystemVerilog
module spi_transmit_axi_stream (
    input  wire         clk,
    input  wire         reset,
    // AXI-Stream Slave Interface
    input  wire [15:0]  s_axis_tdata,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    // AXI-Stream Master Interface (optional for tx_done as event)
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast,
    // SPI outputs
    output wire         spi_clk,
    output wire         spi_cs_n,
    output wire         spi_mosi
);

    localparam IDLE     = 2'b00;
    localparam TRANSMIT = 2'b01;
    localparam FINISH   = 2'b10;

    reg  [1:0]   state, state_next;
    reg  [3:0]   bit_counter, bit_counter_next;
    reg  [15:0]  shift_register, shift_register_next;
    reg          spi_clk_reg, spi_clk_reg_next;
    reg          tx_busy_reg, tx_busy_reg_next;
    reg          tx_done_reg, tx_done_reg_next;
    reg          tvalid_reg, tvalid_reg_next;
    reg          tlast_reg, tlast_reg_next;

    // Borrow subtractor signals
    reg  [15:0]  bit_counter_sub_a;
    reg  [15:0]  bit_counter_sub_b;
    wire [15:0]  bit_counter_sub_result;
    wire         bit_counter_borrow_out;

    // AXI-Stream handshake for input
    assign s_axis_tready = (state == IDLE) && !tx_busy_reg && !tvalid_reg;

    // AXI-Stream handshake for output
    assign m_axis_tvalid = tvalid_reg;
    assign m_axis_tlast  = tlast_reg;

    // SPI outputs
    assign spi_mosi = shift_register[15];
    assign spi_clk  = (state == TRANSMIT) ? spi_clk_reg : 1'b0;
    assign spi_cs_n = (state == IDLE || state == FINISH);

    // State register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state           <= IDLE;
            bit_counter     <= 4'd0;
            shift_register  <= 16'd0;
            spi_clk_reg     <= 1'b0;
            tx_busy_reg     <= 1'b0;
            tx_done_reg     <= 1'b0;
            tvalid_reg      <= 1'b0;
            tlast_reg       <= 1'b0;
        end else begin
            state           <= state_next;
            bit_counter     <= bit_counter_next;
            shift_register  <= shift_register_next;
            spi_clk_reg     <= spi_clk_reg_next;
            tx_busy_reg     <= tx_busy_reg_next;
            tx_done_reg     <= tx_done_reg_next;
            tvalid_reg      <= tvalid_reg_next;
            tlast_reg       <= tlast_reg_next;
        end
    end

    // Next-state logic
    always @* begin
        state_next          = state;
        bit_counter_next    = bit_counter;
        shift_register_next = shift_register;
        spi_clk_reg_next    = spi_clk_reg;
        tx_busy_reg_next    = tx_busy_reg;
        tx_done_reg_next    = tx_done_reg;
        tvalid_reg_next     = tvalid_reg;
        tlast_reg_next      = tlast_reg;

        bit_counter_sub_a   = {12'd0, bit_counter};
        bit_counter_sub_b   = 16'd1;

        case (state)
            IDLE: begin
                tx_done_reg_next      = 1'b0;
                spi_clk_reg_next      = 1'b0;
                if (s_axis_tvalid && s_axis_tready) begin
                    shift_register_next = s_axis_tdata;
                    bit_counter_next    = 4'd15;
                    tx_busy_reg_next    = 1'b1;
                    state_next          = TRANSMIT;
                end
            end
            TRANSMIT: begin
                spi_clk_reg_next = ~spi_clk_reg;
                if (!spi_clk_reg) begin // falling edge
                    if (bit_counter == 0) begin
                        state_next = FINISH;
                    end else begin
                        bit_counter_next    = bit_counter_sub_result[3:0];
                        shift_register_next = {shift_register[14:0], 1'b0};
                    end
                end
            end
            FINISH: begin
                tx_busy_reg_next = 1'b0;
                tx_done_reg_next = 1'b1;
                // Generate tvalid and tlast pulse for one cycle
                if (!tvalid_reg) begin
                    tvalid_reg_next = 1'b1;
                    tlast_reg_next  = 1'b1;
                end
                // Wait for AXI-Stream master to accept the done event
                if (tvalid_reg && m_axis_tready) begin
                    tvalid_reg_next = 1'b0;
                    tlast_reg_next  = 1'b0;
                    state_next      = IDLE;
                end
            end
            default: begin
                state_next = IDLE;
            end
        endcase
    end

    // 16-bit Borrow Subtractor
    borrow_subtractor_16bit u_borrow_subtractor_16bit (
        .minuend   (bit_counter_sub_a),
        .subtrahend(bit_counter_sub_b),
        .difference(bit_counter_sub_result),
        .borrow_out(bit_counter_borrow_out)
    );

endmodule

// 16-bit Borrow Subtractor Module
module borrow_subtractor_16bit (
    input  wire [15:0] minuend,
    input  wire [15:0] subtrahend,
    output wire [15:0] difference,
    output wire        borrow_out
);
    wire [15:0] borrow_chain;
    wire [15:0] diff;

    assign {borrow_chain[0], diff[0]} = minuend[0] - subtrahend[0];
    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin : gen_borrow_chain
            assign {borrow_chain[i], diff[i]} = minuend[i] - subtrahend[i] - borrow_chain[i-1];
        end
    endgenerate

    assign difference = diff;
    assign borrow_out = borrow_chain[15];

endmodule