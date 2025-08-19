//SystemVerilog
// Top-level module for CAN FD Extended Frame handling
// Instantiates Transmitter and Receiver sub-modules.
module CANFD_ExtFrame #(
    parameter DATA_WIDTH = 64,    // Max CAN FD data length
    parameter ID_WIDTH = 29       // Extended frame ID width
)(
    input wire clk,
    input wire rst_n,
    input wire can_rx,
    output wire can_tx,             // Output from Transmitter
    input wire [ID_WIDTH-1:0] ext_id,
    input wire [DATA_WIDTH-1:0] tx_payload,
    input wire tx_fd_enable,       // FD mode enable
    output wire [DATA_WIDTH-1:0] rx_payload, // Output from Receiver
    output wire [ID_WIDTH-1:0] rx_id,        // Output from Receiver
    output wire rx_ext,             // Output from Receiver
    output wire rx_fd,              // Output from Receiver
    input wire tx_start,
    output wire tx_done             // Output from Transmitter
);

    // Instantiate the Transmitter module
    CANFD_Transmitter #(
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .ext_id(ext_id),
        .tx_payload(tx_payload),
        .tx_fd_enable(tx_fd_enable),
        .can_tx(can_tx),
        .tx_done(tx_done)
    );

    // Instantiate the Receiver module
    CANFD_Receiver #(
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .can_rx(can_rx),
        .rx_payload(rx_payload),
        .rx_id(rx_id),
        .rx_ext(rx_ext),
        .rx_fd(rx_fd)
    );

endmodule

// CAN FD Extended Frame Transmitter Module
// Handles the state machine and logic for transmitting a CAN FD frame.
module CANFD_Transmitter #(
    parameter DATA_WIDTH = 64,    // Max CAN FD data length
    parameter ID_WIDTH = 29       // Extended frame ID width
)(
    input wire clk,
    input wire rst_n,
    input wire tx_start,
    input wire [ID_WIDTH-1:0] ext_id,
    input wire [DATA_WIDTH-1:0] tx_payload,
    input wire tx_fd_enable,       // FD mode enable
    output reg can_tx,
    output reg tx_done
);
    // Frame structure definitions
    localparam SOF = 1'b0;
    localparam EOF = 1'b1;

    // State definitions (Binary Encoding)
    localparam [2:0]
        STATE_IDLE      = 3'b000,
        STATE_SEND_SOF  = 3'b001,
        STATE_SEND_ID   = 3'b010,
        STATE_SEND_FD_FLAG= 3'b011,
        STATE_SEND_DLC  = 3'b100,
        STATE_SEND_DATA = 3'b101,
        STATE_SEND_CRC  = 3'b110,
        STATE_SEND_EOF  = 3'b111;

    reg [2:0] tx_state; // State register width reduced for binary encoding
    reg [7:0] bit_cnt;
    reg [ID_WIDTH-1:0] tx_id_reg;
    reg [DATA_WIDTH-1:0] tx_data_reg;
    reg [3:0] dlc;

    // Transmit state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= STATE_IDLE;
            can_tx <= 1'b1; // Default recessive state
            tx_done <= 0;
            bit_cnt <= 0;
            tx_id_reg <= 0;
            tx_data_reg <= 0;
            dlc <= 0;
        end else begin
            case(tx_state)
                STATE_IDLE: begin
                    can_tx <= 1'b1; // Keep bus recessive
                    tx_done <= 1'b0; // Not done transmitting
                    if (tx_start) begin
                        tx_id_reg <= ext_id;
                        tx_data_reg <= tx_payload;
                        // Calculate DLC based on DATA_WIDTH (simplified, assumes full data)
                        // A real CAN FD DLC mapping is more complex
                        dlc <= (DATA_WIDTH+7)/8;
                        tx_state <= STATE_SEND_SOF;
                    end
                end

                STATE_SEND_SOF: begin
                    can_tx <= SOF; // Dominant
                    tx_state <= STATE_SEND_ID;
                    bit_cnt <= ID_WIDTH-1; // Start with MSB of ID
                end

                STATE_SEND_ID: begin
                    can_tx <= tx_id_reg[bit_cnt];
                    if (bit_cnt == 0) begin
                        tx_state <= STATE_SEND_FD_FLAG;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end

                STATE_SEND_FD_FLAG: begin
                    can_tx <= tx_fd_enable;  // FDF bit (1 for FD, 0 for Classic)
                    tx_state <= STATE_SEND_DLC;
                    bit_cnt <= 3; // Start with MSB of 4-bit DLC
                end

                STATE_SEND_DLC: begin
                    can_tx <= dlc[bit_cnt];
                    if (bit_cnt == 0) begin
                        tx_state <= STATE_SEND_DATA;
                        bit_cnt <= DATA_WIDTH-1; // Start with MSB of data
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end

                STATE_SEND_DATA: begin
                    can_tx <= tx_data_reg[bit_cnt];
                    if (bit_cnt == 0) begin
                        tx_state <= STATE_SEND_CRC;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end

                STATE_SEND_CRC: begin
                    // CRC generation logic (simplified from original code)
                    // This is NOT a correct CAN CRC calculation
                    can_tx <= ^tx_data_reg; // Example placeholder output
                    tx_state <= STATE_SEND_EOF;
                end

                STATE_SEND_EOF: begin
                    can_tx <= EOF; // Recessive
                    tx_done <= 1'b1; // Transmission finished
                    tx_state <= STATE_IDLE;
                end

                default: begin
                    // Handle potential invalid states by returning to IDLE
                    tx_state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule

// CAN FD Extended Frame Receiver Module
// Handles basic reception logic based on the original code's structure.
// Note: This is a very simplified receiver and lacks many CAN features
// like synchronization, bit stuffing, ACK, error handling, etc.
module CANFD_Receiver #(
    parameter DATA_WIDTH = 64,    // Max CAN FD data length
    parameter ID_WIDTH = 29       // Extended frame ID width
)(
    input wire clk,
    input wire rst_n,
    input wire can_rx,
    output reg [DATA_WIDTH-1:0] rx_payload,
    output reg [ID_WIDTH-1:0] rx_id,
    output reg rx_ext,             // Extended frame flag (simplified detection)
    output reg rx_fd               // FD frame flag (not implemented in original receive logic)
);
    // Frame structure definitions (for reference in receive)
    localparam SOF = 1'b0;
    // localparam EOF = 1'b1; // Not used in original receive logic

    reg [ID_WIDTH-1:0] rx_id_reg;
    reg [DATA_WIDTH-1:0] rx_data_reg;
    reg rx_active; // Flag to indicate if reception is ongoing after SOF

    // Counter added to replicate original sequential shifting behavior
    reg [9:0] bit_index; // Counter for up to ID_WIDTH + DATA_WIDTH bits (approx 29 + 64 = 93, 10 bits is sufficient)


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_id_reg <= 0;
            rx_data_reg <= 0;
            rx_ext <= 0;
            rx_fd <= 0;
            rx_payload <= 0;
            rx_id <= 0;
            rx_active <= 0;
            bit_index <= 0;
        end else begin
            // Simplified receive logic based on original code
            // This logic just shifts bits in after detecting SOF.
            // It does not handle bit timing, stuffing, errors, etc.
            if (can_rx == SOF && !rx_active) begin
                // Detected start of frame (simplified: assumes first dominant bit is SOF)
                rx_id_reg <= 0;
                rx_data_reg <= 0;
                rx_ext <= 1'b1;  // Assume extended frame as per module name
                rx_fd <= 0; // FD detection not present in original receive
                rx_active <= 1;
                bit_index <= 0; // Reset counter on new frame start
            end else if (rx_active) begin
                // Shift incoming bits
                // Original logic just continuously shifts.
                // A real receiver would use a state machine and bit counter.
                // Preserving original simplified behavior: first ID_WIDTH bits go to rx_id_reg, then DATA_WIDTH bits to rx_data_reg.
                // This requires tracking which bit is being received, which was implicitly done by the shift register length in the original.
                // Let's add a counter to replicate the original sequential shifting effect.

                // Check if counter is within bounds before incrementing
                if (bit_index < ID_WIDTH + DATA_WIDTH + 16) begin // Max expected bits + margin
                   bit_index <= bit_index + 1;
                end else begin
                   // Basic timeout if reception goes on too long
                   rx_active <= 0;
                   bit_index <= 0;
                end


                if (bit_index > 0) begin // Start shifting after the SOF bit (bit_index 0)
                    if (bit_index <= ID_WIDTH) begin
                        // Receive ID bits (bit_index 1 to ID_WIDTH)
                        rx_id_reg <= {rx_id_reg[ID_WIDTH-2:0], can_rx};
                    end else if (bit_index > ID_WIDTH && bit_index <= ID_WIDTH + DATA_WIDTH) begin
                        // Receive Data bits (bit_index ID_WIDTH+1 to ID_WIDTH+DATA_WIDTH)
                        rx_data_reg <= {rx_data_reg[DATA_WIDTH-2:0], can_rx};
                    end
                    // Note: Original logic doesn't explicitly stop after data,
                    // it just keeps shifting. This refactoring replicates that.
                    // A real receiver would transition states for CRC, ACK, EOF.

                    // Simple reset mechanism if bus goes recessive for a sustained period?
                    // Original code didn't have this. Keeping it simple.
                    // Let's add a basic timeout or end-of-frame detection based on recessive bus
                    // This is an enhancement for basic functionality, not strictly in original
                    // but needed for 'rx_active' to ever go low.
                    // A real CAN module would detect EOF pattern.
                    // For this simplified version, let's assume reception stops after a certain number of bits.
                    if (bit_index >= ID_WIDTH + DATA_WIDTH + 16) begin // Allow some margin for CRC/ACK/EOF
                        rx_active <= 0;
                        bit_index <= 0;
                    end
                end
            end

            // Update outputs - outputs should ideally be updated at the end of a frame reception
            // but the original code seems to just expose the shifting registers.
            // Keeping the original behavior of continuously updating outputs.
            rx_payload <= rx_data_reg;
            rx_id <= rx_id_reg;
            // rx_ext and rx_fd are updated when SOF is detected
        end
    end

endmodule