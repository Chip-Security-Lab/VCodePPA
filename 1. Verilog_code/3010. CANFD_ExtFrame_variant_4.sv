//SystemVerilog
// serial_bit_transmitter module
// Transmits data serially, MSB first.
module serial_bit_transmitter #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire start,          // Pulse to start transmission (active high)
    input wire [DATA_WIDTH-1:0] data_in,
    output reg serial_out,
    output reg busy,           // High when transmitting
    output reg done            // Pulsed high for one cycle when transmission finishes
);

    reg [DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(DATA_WIDTH):0] bit_count; // Counter for bits sent
    reg tx_state; // 0: IDLE, 1: SENDING

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= 0;
            serial_out <= 1'b1; // CAN recessive is high
            busy <= 0;
            done <= 0;
            bit_count <= 0;
            shift_reg <= 0;
        end else begin
            done <= 0; // Clear done by default

            case (tx_state)
                0: begin // IDLE
                    serial_out <= 1'b1; // Recessive
                    busy <= 0;
                    if (start) begin
                        tx_state <= 1;
                        busy <= 1;
                        shift_reg <= data_in;
                        bit_count <= DATA_WIDTH; // Number of bits to send
                        // Outputting the first bit happens in the SENDING state on the next cycle
                    end
                end
                1: begin // SENDING
                    serial_out <= shift_reg[DATA_WIDTH-1]; // Output MSB
                    shift_reg <= shift_reg << 1; // Shift left
                    
                    if (bit_count == 1) begin // Just sent the last bit
                        tx_state <= 0; // Back to IDLE
                        busy <= 0;
                        done <= 1; // Signal completion
                        // serial_out will be set to recessive in the next cycle's IDLE state
                    end else begin
                        bit_count <= bit_count - 1;
                    end
                end
            endcase
        end
    end

endmodule

// Top module CANFD_ExtFrame
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
    output reg rx_fd,              // FD frame flag (Note: original receive logic doesn't set this)
    input wire tx_start,
    output reg tx_done
);
    // Frame structure definitions
    localparam SOF = 1'b0; // Dominant
    localparam EOF = 1'b1; // Recessive
    
    // Transmit State definitions
    localparam IDLE = 4'd0;
    localparam SEND_SOF = 4'd1;
    localparam START_SEND_ID = 4'd2;
    localparam WAIT_SEND_ID = 4'd3;
    localparam SEND_FD_FLAG = 4'd4;
    localparam START_SEND_DLC = 4'd5;
    localparam WAIT_SEND_DLC = 4'd6;
    localparam START_SEND_DATA = 4'd7;
    localparam WAIT_SEND_DATA = 4'd8;
    localparam SEND_CRC = 4'd9;
    localparam SEND_EOF = 4'd10;

    reg [3:0] tx_state;
    reg [ID_WIDTH-1:0] tx_id_reg;
    reg [DATA_WIDTH-1:0] tx_data_reg;
    reg [3:0] dlc;
    // reg crc_enable; // Not used in original simplified CRC

    // Signals for serial transmitter sub-modules
    reg start_tx_id;
    wire serial_out_id;
    wire busy_tx_id;
    wire done_tx_id;

    reg start_tx_dlc;
    wire serial_out_dlc;
    wire busy_tx_dlc;
    wire done_tx_dlc;

    reg start_tx_data;
    wire serial_out_data;
    wire busy_tx_data;
    wire done_tx_data;

    // Instantiate serial transmitters for different frame sections
    serial_bit_transmitter #(
        .DATA_WIDTH(ID_WIDTH)
    ) tx_id_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_tx_id),
        .data_in(tx_id_reg),
        .serial_out(serial_out_id),
        .busy(busy_tx_id),
        .done(done_tx_id)
    );

    serial_bit_transmitter #(
        .DATA_WIDTH(4) // DLC is 4 bits
    ) tx_dlc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_tx_dlc),
        .data_in(dlc),
        .serial_out(serial_out_dlc),
        .busy(busy_tx_dlc),
        .done(done_tx_dlc)
    );

    serial_bit_transmitter #(
        .DATA_WIDTH(DATA_WIDTH)
    ) tx_data_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_tx_data),
        .data_in(tx_data_reg),
        .serial_out(serial_out_data),
        .busy(busy_tx_data),
        .done(done_tx_data)
    );

    // Mux for the main can_tx output based on current state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            can_tx <= 1'b1; // Recessive state on reset
        end else begin
            case (tx_state)
                IDLE: can_tx <= 1'b1; // Recessive
                SEND_SOF: can_tx <= SOF; // Dominant (0)
                START_SEND_ID, WAIT_SEND_ID: can_tx <= serial_out_id; // Output from ID transmitter
                SEND_FD_FLAG: can_tx <= tx_fd_enable; // 0 or 1
                START_SEND_DLC, WAIT_SEND_DLC: can_tx <= serial_out_dlc; // Output from DLC transmitter
                START_SEND_DATA, WAIT_SEND_DATA: can_tx <= serial_out_data; // Output from Data transmitter
                SEND_CRC: can_tx <= ^tx_data_reg; // Simplified CRC (XOR reduction of original data)
                SEND_EOF: can_tx <= EOF; // Recessive (1)
                default: can_tx <= 1'b1; // Should not happen, default to recessive
            endcase
        end
    end

    // Transmit state machine logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= IDLE;
            tx_done <= 0;
            tx_id_reg <= 0;
            tx_data_reg <= 0;
            dlc <= 0;
            // crc_enable <= 0; // Not used
            start_tx_id <= 0;
            start_tx_dlc <= 0;
            start_tx_data <= 0;
        end else begin
            // Default values for start signals (pulse logic)
            start_tx_id <= 0;
            start_tx_dlc <= 0;
            start_tx_data <= 0;
            tx_done <= 0; // Default

            case(tx_state)
                IDLE: begin
                    if (tx_start) begin
                        tx_id_reg <= ext_id;
                        tx_data_reg <= tx_payload;
                        // Calculate DLC based on DATA_WIDTH. This is a simplified example.
                        // Real CAN FD DLC mapping is specific (0-15 -> 0-64 bytes)
                        // Using a simple byte count here as in original.
                        dlc <= (DATA_WIDTH+7)/8; 
                        tx_state <= SEND_SOF;
                    end
                end
                
                SEND_SOF: begin
                    tx_state <= START_SEND_ID;
                end
                
                START_SEND_ID: begin
                    start_tx_id <= 1; // Pulse start for ID transmitter
                    tx_state <= WAIT_SEND_ID;
                end

                WAIT_SEND_ID: begin
                    if (done_tx_id) begin
                        tx_state <= SEND_FD_FLAG;
                    end
                end
                
                SEND_FD_FLAG: begin
                    tx_state <= START_SEND_DLC;
                end
                
                START_SEND_DLC: begin
                    start_tx_dlc <= 1; // Pulse start for DLC transmitter
                    tx_state <= WAIT_SEND_DLC;
                end

                WAIT_SEND_DLC: begin
                    if (done_tx_dlc) begin
                        tx_state <= START_SEND_DATA;
                    end
                end
                
                START_SEND_DATA: begin
                    start_tx_data <= 1; // Pulse start for Data transmitter
                    tx_state <= WAIT_SEND_DATA;
                end

                WAIT_SEND_DATA: begin
                    if (done_tx_data) begin
                        tx_state <= SEND_CRC;
                    end
                end
                
                SEND_CRC: begin
                    // CRC takes 1 cycle in this simplified version
                    tx_state <= SEND_EOF;
                end
                
                SEND_EOF: begin
                    tx_done <= 1'b1; // Signal end of transmission
                    tx_state <= IDLE;
                end
                
                default: begin
                    tx_state <= IDLE; // Should not happen
                end
            endcase
        end
    end

    // Receive logic (kept as is, as it's simple and unique in structure)
    reg [ID_WIDTH-1:0] rx_id_reg;
    reg [DATA_WIDTH-1:0] rx_data_reg;

    // Pre-calculate conditions for register updates
    wire is_sof = (can_rx == SOF);
    // Assuming rx_id_reg is used as a bit counter for ID phase
    // The original logic implies ID phase continues until rx_id_reg reaches ID_WIDTH
    // This might be a misunderstanding of CAN timing, but preserving original logic structure
    wire is_id_phase = (rx_id_reg < ID_WIDTH); 

    wire update_id_reg = !is_sof && is_id_phase;
    wire update_data_reg = !is_sof && !is_id_phase;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_id_reg <= 0;
            rx_data_reg <= 0;
            rx_ext <= 0;
            rx_fd <= 0; // Original logic never sets rx_fd
            rx_payload <= 0;
            rx_id <= 0;
        end else begin
            // Flattened if-else structure
            if (is_sof) begin
                rx_id_reg <= 0; // Reset counter/register on SOF
                rx_data_reg <= 0; // Reset data on SOF
                rx_ext <= 1'b1;  // Identify extended frame on SOF (simplified)
                // rx_fd is not set by the original receive logic
            end else if (update_id_reg) begin // Equivalent to !is_sof && is_id_phase
                // Shift in the received bit into ID register
                rx_id_reg <= {rx_id_reg[ID_WIDTH-2:0], can_rx};
            end else if (update_data_reg) begin // Equivalent to !is_sof && !is_id_phase
                // Shift in the received bit into Data register
                rx_data_reg <= {rx_data_reg[DATA_WIDTH-2:0], can_rx};
            end
            
            // Update outputs (always updated as per original code)
            rx_payload <= rx_data_reg;
            rx_id <= rx_id_reg;
        end
    end

endmodule