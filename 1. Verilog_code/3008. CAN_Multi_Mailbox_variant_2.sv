//SystemVerilog
module CAN_Multi_Mailbox #(
    parameter NUM_MAILBOXES = 4,
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input can_rx,
    output reg can_tx,
    input [DATA_WIDTH-1:0] tx_data [0:NUM_MAILBOXES-1],
    output [DATA_WIDTH-1:0] rx_data [0:NUM_MAILBOXES-1],
    input [NUM_MAILBOXES-1:0] tx_request,
    output reg [NUM_MAILBOXES-1:0] tx_complete
);

    // Internal Registers (Sequential Logic Outputs)
    reg can_tx_ack_reg;
    reg [$clog2(NUM_MAILBOXES)-1:0] mailbox_select_reg; // Use appropriate width for mailbox index
    reg [NUM_MAILBOXES-1:0] tx_active_array_reg;
    reg [DATA_WIDTH-1:0] tx_reg_array_reg [0:NUM_MAILBOXES-1];
    reg [DATA_WIDTH-1:0] rx_reg_array_reg [0:NUM_MAILBOXES-1];

    // Internal Wires (Combinational Logic Outputs / Inputs to Sequential Logic)
    wire [NUM_MAILBOXES-1:0] is_mailbox_selected_comb;
    wire all_tx_inactive_comb;
    wire [$clog2(NUM_MAILBOXES)-1:0] next_mailbox_select_comb;
    wire selected_tx_bit_comb;
    wire can_tx_ack_comb;

    //------------------------------------------------------------------------
    // Combinational Logic Block - Global Control Signals
    //------------------------------------------------------------------------

    // Determine if all mailboxes are inactive
    assign all_tx_inactive_comb = ~(&tx_active_array_reg);

    // Calculate next mailbox select index
    // Note: This logic assumes NUM_MAILBOXES is a power of 2 or handles wrap-around correctly
    // For non-power of 2, need modulo or explicit check. Assuming power of 2 or similar simple wrap for now.
    assign next_mailbox_select_comb = all_tx_inactive_comb ? (mailbox_select_reg + 1) % NUM_MAILBOXES : mailbox_select_reg;

    // Select the TX bit from the currently selected mailbox register
    assign selected_tx_bit_comb = tx_reg_array_reg[mailbox_select_reg][DATA_WIDTH-1];

    // Simulate TX acknowledge logic (example: ack for mailbox 0)
    assign can_tx_ack_comb = (mailbox_select_reg == 0); // Placeholder logic

    //------------------------------------------------------------------------
    // Sequential Logic Block - Global Control Registers
    //------------------------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mailbox_select_reg <= 0;
            can_tx <= 1'b1; // Assuming initial idle state is high
            can_tx_ack_reg <= 1'b0;
        end else begin
            // Update mailbox select register
            mailbox_select_reg <= next_mailbox_select_comb;

            // Update CAN TX output register
            can_tx <= selected_tx_bit_comb;

            // Update TX acknowledge register
            can_tx_ack_reg <= can_tx_ack_comb;
        end
    end

    //------------------------------------------------------------------------
    // Generate Block - Per-Mailbox Logic
    //------------------------------------------------------------------------

    genvar i;
    generate
        for (i=0; i<NUM_MAILBOXES; i=i+1) begin : mailbox_gen

            // Intermediate signals for case statement outputs
            reg [DATA_WIDTH-1:0] next_tx_reg_array_reg_i;
            reg next_tx_active_array_reg_i;

            //--------------------------------------------------------------------
            // Combinational Logic - Per-Mailbox Signals
            //--------------------------------------------------------------------

            // Determine if this mailbox is currently selected
            assign is_mailbox_selected_comb[i] = (mailbox_select_reg == i);

            // Assign output rx_data from the RX register
            assign rx_data[i] = rx_reg_array_reg[i];

            //--------------------------------------------------------------------
            // Sequential Logic - Per-Mailbox Registers
            //--------------------------------------------------------------------

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    tx_reg_array_reg[i] <= 0;
                    rx_reg_array_reg[i] <= 0;
                    tx_active_array_reg[i] <= 0;
                    tx_complete[i] <= 0;
                end else begin
                    // Default assignments (retain old value)
                    next_tx_reg_array_reg_i = tx_reg_array_reg[i];
                    next_tx_active_array_reg_i = tx_active_array_reg[i];

                    // TX Data Register and Active Flag Update (Case conversion)
                    // Conditions: tx_request[i], (can_tx_ack_reg && tx_active_array_reg[i])
                    case ({tx_request[i], (can_tx_ack_reg && tx_active_array_reg[i])})
                        2'b10, 2'b11: begin // tx_request[i] is high (priority case)
                            next_tx_reg_array_reg_i = tx_data[i];
                            next_tx_active_array_reg_i = 1'b1;
                        end
                        2'b01: begin // tx_request[i] is false, (can_tx_ack_reg && tx_active_array_reg[i]) is true
                            next_tx_active_array_reg_i = 1'b0;
                        end
                        // 2'b00: both false, default assignments handle this (retain value)
                        default: begin // Should not happen with 2-bit case, but good practice
                            next_tx_reg_array_reg_i = tx_reg_array_reg[i];
                            next_tx_active_array_reg_i = tx_active_array_reg[i];
                        end
                    endcase

                    // Assign updated values to registers
                    tx_reg_array_reg[i] <= next_tx_reg_array_reg_i;
                    tx_active_array_reg[i] <= next_tx_active_array_reg_i;


                    // TX Complete Flag Update (pulse) - Kept as if-else as it's not a cascade
                    if (can_tx_ack_reg && tx_active_array_reg[i]) begin
                         tx_complete[i] <= 1'b1;
                    end else begin
                         tx_complete[i] <= 1'b0; // Clear after one cycle
                    end

                    // RX Data Register Update (Shift register) - Kept as if
                    if (is_mailbox_selected_comb[i]) begin
                        rx_reg_array_reg[i] <= {rx_reg_array_reg[i][DATA_WIDTH-2:0], can_rx};
                    end
                end
            end
        end
    endgenerate

endmodule