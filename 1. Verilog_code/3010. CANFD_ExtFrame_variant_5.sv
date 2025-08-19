//SystemVerilog
module CANFD_ExtFrame #(
    parameter DATA_WIDTH = 64,    // Max CAN FD data length
    parameter ID_WIDTH = 29       // Extended frame ID width
)(
    input wire clk,
    input wire rst_n,
    input wire can_rx,
    output reg can_tx,
    input wire [ID_WIDTH-1:0] ext_id,
    input wire [DATA_WIDTH-1:0] tx_payload,
    input wire tx_fd_enable,       // FD mode enable
    output reg [DATA_WIDTH-1:0] rx_payload,
    output reg [ID_WIDTH-1:0] rx_id,
    output reg rx_ext,             // Extended frame flag
    output reg rx_fd,              // FD frame flag
    input wire tx_start,
    output reg tx_done
);
    // Frame structure definitions
    localparam SOF = 1'b0;
    localparam EOF = 1'b1;

    // State definitions
    localparam IDLE = 3'd0;
    localparam SEND_SOF = 3'd1;
    localparam SEND_ID = 3'd2;
    localparam SEND_FD_FLAG = 3'd3;
    localparam SEND_DLC = 3'd4;
    localparam SEND_DATA = 3'd5;
    localparam SEND_CRC = 3'd6;
    localparam SEND_EOF = 3'd7;

    reg [2:0] tx_state;
    reg [7:0] bit_cnt;
    reg [ID_WIDTH-1:0] tx_id_reg;
    reg [DATA_WIDTH-1:0] tx_data_reg;
    reg [3:0] dlc;
    reg crc_enable;

    // Conditional inversion subtractor for bit_cnt - 1
    // A - B = A + (~B) + 1
    // Here B = 1 (8'd1)
    // ~B = ~8'd1 = 8'b1111_1110 (8'hfe)
    // A - 1 = A + 8'hfe + 1'b1 = A + 8'hff
    wire [7:0] bit_cnt_decremented = bit_cnt + 8'hff;


    // Transmit state machine - Flattened if-else structure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= IDLE;
            can_tx <= 1'b1;
            tx_done <= 0;
            bit_cnt <= 0;
            tx_id_reg <= 0;
            tx_data_reg <= 0;
            dlc <= 0;
            crc_enable <= 0;
        end else begin
            // Default state transition if no condition is met (shouldn't happen with defined states)
            // but included for completeness based on original default case
            // tx_state <= tx_state; // Implicitly holds
            // can_tx, tx_done, bit_cnt, tx_id_reg, tx_data_reg, dlc, crc_enable hold their values by default

            if (tx_state == IDLE && tx_start) begin
                tx_id_reg <= ext_id;
                tx_data_reg <= tx_payload;
                dlc <= (DATA_WIDTH+7)/8; // Calculate DLC
                tx_state <= SEND_SOF;
                tx_done <= 1'b0;
            end else if (tx_state == SEND_SOF) begin
                can_tx <= SOF;
                tx_state <= SEND_ID;
                bit_cnt <= ID_WIDTH-1;
            end else if (tx_state == SEND_ID && bit_cnt == 0) begin
                can_tx <= tx_id_reg[bit_cnt];
                tx_state <= SEND_FD_FLAG;
            end else if (tx_state == SEND_ID && bit_cnt != 0) begin
                can_tx <= tx_id_reg[bit_cnt];
                // Replace subtraction with conditional inversion method
                bit_cnt <= bit_cnt_decremented;
            end else if (tx_state == SEND_FD_FLAG) begin
                can_tx <= tx_fd_enable;  // FD mode flag bit
                tx_state <= SEND_DLC;
                bit_cnt <= 3; // Set for DLC bits
            end else if (tx_state == SEND_DLC && bit_cnt == 0) begin
                can_tx <= dlc[bit_cnt];
                tx_state <= SEND_DATA;
                bit_cnt <= DATA_WIDTH-1;
            end else if (tx_state == SEND_DLC && bit_cnt != 0) begin
                can_tx <= dlc[bit_cnt];
                // Replace subtraction with conditional inversion method
                bit_cnt <= bit_cnt_decremented;
            end else if (tx_state == SEND_DATA && bit_cnt == 0) begin
                can_tx <= tx_data_reg[bit_cnt];
                tx_state <= SEND_CRC;
            end else if (tx_state == SEND_DATA && bit_cnt != 0) begin
                can_tx <= tx_data_reg[bit_cnt];
                // Replace subtraction with conditional inversion method
                bit_cnt <= bit_cnt_decremented;
            end else if (tx_state == SEND_CRC) begin
                // CRC generation logic (simplified)
                can_tx <= ^tx_data_reg; // Example placeholder
                tx_state <= SEND_EOF;
            end else if (tx_state == SEND_EOF) begin
                can_tx <= EOF;
                tx_done <= 1'b1;
                tx_state <= IDLE;
            end else begin // Handles default case from original or unexpected states
                 tx_state <= IDLE;
            end
        end
    end

    // Receive logic (simplified for core structure) - Already flattened if-else if
    reg [ID_WIDTH-1:0] rx_id_reg;
    reg [DATA_WIDTH-1:0] rx_data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_id_reg <= 0;
            rx_data_reg <= 0;
            rx_ext <= 0;
            rx_fd <= 0;
            rx_payload <= 0;
            rx_id <= 0;
        end else begin
            if (can_rx == SOF) begin
                rx_id_reg <= 0;
                rx_data_reg <= 0;
                rx_ext <= 1'b1;  // Identify extended frame
                // rx_fd holds
            end else if (rx_id_reg < ID_WIDTH) begin
                rx_id_reg <= {rx_id_reg[ID_WIDTH-2:0], can_rx};
                // rx_data_reg, rx_ext, rx_fd hold
            end else begin // rx_id_reg >= ID_WIDTH (simplified logic)
                rx_data_reg <= {rx_data_reg[DATA_WIDTH-2:0], can_rx};
                // rx_id_reg, rx_ext, rx_fd hold
            end

            // Update outputs - These assignments happen unconditionally every cycle when not in reset
            // Note: In a real CAN receiver, rx_id/rx_payload would be updated upon successful reception/CRC check.
            // This simplified logic updates them continuously with the internal shift register values.
            rx_payload <= rx_data_reg;
            rx_id <= rx_id_reg;
            // rx_ext and rx_fd are assigned conditionally above
        end
    end
endmodule