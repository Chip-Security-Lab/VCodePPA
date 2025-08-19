//SystemVerilog
module CAN_Multi_Mailbox_Pipelined #(
    parameter NUM_MAILBOXES = 4,
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input can_rx,
    output can_tx,
    input [DATA_WIDTH-1:0] tx_data [0:NUM_MAILBOXES-1],
    output [DATA_WIDTH-1:0] rx_data [0:NUM_MAILBOXES-1],
    input [NUM_MAILBOXES-1:0] tx_request,
    output [NUM_MAILBOXES-1:0] tx_complete
);

    // Calculate index width
    localparam INDEX_WIDTH = (NUM_MAILBOXES > 1) ? $clog2(NUM_MAILBOXES) : 1;

    // --- Pipeline Registers ---

    // Stage 0 -> Stage 1 Registers
    reg [INDEX_WIDTH-1:0] s0_tx_mailbox_select_reg; // Registered arbitration result

    // Stage 1 -> Stage 2 Registers
    reg [DATA_WIDTH-1:0] s1_selected_tx_data_reg;
    reg [INDEX_WIDTH-1:0] s1_tx_mailbox_select_reg; // Propagated selected index

    // Stage 2 Output Registers (also feedback)
    reg s2_can_tx_reg;
    reg s2_can_tx_ack_reg; // Registered acknowledge signal

    // --- Feedback Signal ---
    // Acknowledge signal from Stage 2, registered, feeds back to Stage 0
    wire s2_can_tx_ack_feedback;
    assign s2_can_tx_ack_feedback = s2_can_tx_ack_reg;


    // --- Stage 0: Input Handling, Rx Accumulation, Tx Buffer, Arbitration ---
    // These are the core state registers updated in Stage 0 logic.
    // They are updated based on inputs and feedback signals from later stages (pipelined).
    reg [DATA_WIDTH-1:0] s0_mailbox_tx_buffer [0:NUM_MAILBOXES-1];
    reg [DATA_WIDTH-1:0] s0_mailbox_rx_buffer [0:NUM_MAILBOXES-1];
    reg [NUM_MAILBOXES-1:0] s0_mailbox_tx_active;
    reg [NUM_MAILBOXES-1:0] s0_mailbox_tx_complete;

    // Stage 0: Arbitration Logic (Sequential)
    // Determines the mailbox index selected for the *next* cycle's Stage 1 data selection.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s0_tx_mailbox_select_reg <= 0;
        end else begin
            // Simple Round-Robin arbitration
            s0_tx_mailbox_select_reg <= (s0_tx_mailbox_select_reg == NUM_MAILBOXES - 1) ? 0 : s0_tx_mailbox_select_reg + 1;
        end
    end

    // Stage 0: Per-mailbox logic (Tx buffer load, Rx accumulation, Tx state update) (Sequential)
    // Updates mailbox states based on inputs and feedback from Stage 2 (pipelined).
    genvar i;
    generate
        for (i=0; i<NUM_MAILBOXES; i=i+1) begin : s0_mailbox_logic
            // Combinational signal for ACK condition check within Stage 0 logic
            wire s0_ack_condition_met;
            assign s0_ack_condition_met = s2_can_tx_ack_feedback && s0_mailbox_tx_active[i] && (s1_tx_mailbox_select_reg == i);

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    s0_mailbox_tx_buffer[i]  <= {DATA_WIDTH{1'b0}};
                    s0_mailbox_rx_buffer[i]  <= {DATA_WIDTH{1'b0}};
                    s0_mailbox_tx_active[i]  <= 1'b0;
                    s0_mailbox_tx_complete[i] <= 1'b0;
                end else begin
                    // TX Data Loading and State Update
                    if (tx_request[i]) begin
                        s0_mailbox_tx_buffer[i] <= tx_data[i]; // Load new data
                        s0_mailbox_tx_active[i] <= 1'b1;       // Activate TX
                        s0_mailbox_tx_complete[i] <= 1'b0;      // Clear complete on new request
                    end else if (s0_ack_condition_met) begin
                         // This mailbox finished TX (acknowledged) - uses pipelined ACK and select
                        s0_mailbox_tx_active[i] <= 1'b0;
                        s0_mailbox_tx_complete[i] <= 1'b1; // Set complete flag
                    end else begin
                         // Clear complete flag after one cycle if not re-requested and was complete
                         if (s0_mailbox_tx_complete[i] == 1'b1) begin
                             s0_mailbox_tx_complete[i] <= 1'b0;
                         end
                    end

                    // RX Data Accumulation
                    // Accumulates based on the mailbox index selected *one* cycle ago (s0_tx_mailbox_select_reg)
                    // This aligns the RX data with the index that is currently in Stage 1.
                    if (s0_tx_mailbox_select_reg == i) begin
                        s0_mailbox_rx_buffer[i] <= {s0_mailbox_rx_buffer[i][DATA_WIDTH-2:0], can_rx};
                    end
                end
            end

            // Assign rx_data output directly from Stage 0 buffer register
            assign rx_data[i] = s0_mailbox_rx_buffer[i];
        end
    endgenerate

    // Assign tx_complete output from Stage 0 register
    assign tx_complete = s0_mailbox_tx_complete;


    // --- Stage 1: Transmit Data Selection ---
    // Combinational logic for Stage 1
    wire [DATA_WIDTH-1:0] s1_selected_tx_data_comb;
    wire [INDEX_WIDTH-1:0] s1_tx_mailbox_select_comb;

    // Select data based on registered arbitration result from Stage 0
    assign s1_selected_tx_data_comb = s0_mailbox_tx_buffer[s0_tx_mailbox_select_reg];
    // Propagate the selected index to the next stage for ACK logic
    assign s1_tx_mailbox_select_comb = s0_tx_mailbox_select_reg;

    // Register Stage 1 outputs for Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_selected_tx_data_reg <= {DATA_WIDTH{1'b0}};
            s1_tx_mailbox_select_reg <= 0;
        end else begin
            s1_selected_tx_data_reg <= s1_selected_tx_data_comb;
            s1_tx_mailbox_select_reg <= s1_tx_mailbox_select_comb;
        end
    end


    // --- Stage 2: Transmit Bit Output and Acknowledge Generation ---
    // Combinational logic for Stage 2
    wire s2_can_tx_comb;
    wire s2_can_tx_ack_comb;

    // Output the MSB of the selected data from Stage 1 register
    assign s2_can_tx_comb = s1_selected_tx_data_reg[DATA_WIDTH-1];

    // Generate acknowledge signal based on mailbox selected in Stage 1 register
    // Keeping the original simplified logic: ACK when mailbox 0 is selected
    assign s2_can_tx_ack_comb = (s1_tx_mailbox_select_reg == 0);
    // Note: This ACK logic is not CAN standard compliant.

    // Register Stage 2 outputs (can_tx and feedback ack)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_can_tx_reg     <= 1'b1; // CAN idle state is recessive (1)
            s2_can_tx_ack_reg <= 1'b0; // Reset acknowledge
        end else begin
            s2_can_tx_reg     <= s2_can_tx_comb;
            s2_can_tx_ack_reg <= s2_can_tx_ack_comb;
        end
    end

    // Final Output Assignment for can_tx from Stage 2 register
    assign can_tx = s2_can_tx_reg;


endmodule