//SystemVerilog
module CAN_Multi_Mailbox #(
    parameter NUM_MAILBOXES = 4,
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input can_rx,
    output reg can_tx, // Kept as reg for original reset value
    input [DATA_WIDTH-1:0] tx_data [0:NUM_MAILBOXES-1],
    output [DATA_WIDTH-1:0] rx_data [0:NUM_MAILBOXES-1],
    input [NUM_MAILBOXES-1:0] tx_request,
    output reg [NUM_MAILBOXES-1:0] tx_complete // Kept as reg
);

    // Calculate the required width for mailbox_select
    localparam MAILBOX_SELECT_WIDTH = (NUM_MAILBOXES <= 1) ? 1 : $clog2(NUM_MAILBOXES);

    // Add missing signals and fix array type declarations
    // can_tx_ack kept as reg for original reset value
    reg can_tx_ack;
    reg [MAILBOX_SELECT_WIDTH-1:0] mailbox_select; // Use calculated width
    reg [NUM_MAILBOXES-1:0] tx_active_array;

    reg [DATA_WIDTH-1:0] tx_reg_array [0:NUM_MAILBOXES-1];
    reg [DATA_WIDTH-1:0] rx_reg_array [0:NUM_MAILBOXES-1];

    // Added registers for pipelining critical paths
    reg [DATA_WIDTH-1:0] selected_tx_data_reg; // Pipelines the MUX output for TX data
    reg all_inactive_q;                       // Pipelines the result of !(&tx_active_array)
    reg can_tx_ack_q;                         // Pipelines the mailbox_select == 0 comparison for ACK

    // Mailbox logic
    genvar i;
    generate
        for (i=0; i<NUM_MAILBOXES; i=i+1) begin : mailbox_gen
            // Use a localparam for the current mailbox index for comparison
            localparam CURRENT_MAILBOX_INDEX = i;

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    tx_reg_array[i] <= 0;
                    rx_reg_array[i] <= 0;
                    tx_active_array[i] <= 0;
                    tx_complete[i] <= 0;
                end else begin
                    if (tx_request[i]) begin
                        tx_reg_array[i] <= tx_data[i];
                        tx_active_array[i] <= 1'b1;
                        // tx_complete[i] state is not explicitly changed here in original code when request is high
                    end else if (can_tx_ack_q && tx_active_array[i]) begin // Use pipelined can_tx_ack
                        tx_active_array[i] <= 1'b0;
                        tx_complete[i] <= 1'b1;
                    end else begin
                        tx_complete[i] <= 1'b0; // This branch covers the case where tx_request[i] is low and not (can_tx_ack_q && tx_active_array[i])
                    end

                    // When this mailbox is selected, receive data
                    // This combinatorial path from mailbox_select to register enable is kept
                    if (mailbox_select == CURRENT_MAILBOX_INDEX) begin
                        // Assuming can_rx is 1 bit
                        rx_reg_array[i] <= {rx_reg_array[i][DATA_WIDTH-2:0], can_rx};
                    end
                end
            end

            // Assign rx_data for this mailbox
            assign rx_data[i] = rx_reg_array[i];
        end
    endgenerate

    // Simple arbitration and data multiplexing logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mailbox_select <= {MAILBOX_SELECT_WIDTH{1'b0}}; // Reset with correct width
            can_tx <= 1'b1; // Keep original reset value
            can_tx_ack <= 1'b0; // Keep original reset value

            // Reset new pipeline registers
            selected_tx_data_reg <= {DATA_WIDTH{1'b0}};
            all_inactive_q <= 1'b1;
            can_tx_ack_q <= 1'b0;

        end else begin
            // Pipelined check for all mailboxes inactive
            // Combinatorial path: tx_active_array -> reduction AND -> all_inactive_q input
            all_inactive_q <= !(&tx_active_array);

            // Update mailbox_select based on pipelined check
            // Combinatorial path: all_inactive_q, mailbox_select -> comparison/increment -> mailbox_select input
            if (all_inactive_q) begin // Use the pipelined 'all_inactive' signal
                if (mailbox_select == NUM_MAILBOXES-1) begin
                    mailbox_select <= {MAILBOX_SELECT_WIDTH{1'b0}}; // Wrap around to 0
                end else begin
                    mailbox_select <= mailbox_select + 1; // Increment
                end
            end
            // else mailbox_select holds its value

            // Pipelined MUX for tx_data
            // Combinatorial path: mailbox_select, tx_reg_array -> MUX -> selected_tx_data_reg input
            selected_tx_data_reg <= tx_reg_array[mailbox_select];

            // Send data from the selected mailbox (assuming MSB first)
            // Output the MSB of the registered data
            // Short combinatorial path: selected_tx_data_reg -> can_tx input
            can_tx <= selected_tx_data_reg[DATA_WIDTH-1];

            // Simple send acknowledgement simulation
            // Pipelined comparison for can_tx_ack
            // Combinatorial path: mailbox_select -> comparison -> can_tx_ack_q input
            can_tx_ack_q <= (mailbox_select == {MAILBOX_SELECT_WIDTH{1'b0}});
            // Output the registered can_tx_ack
            // Short combinatorial path: can_tx_ack_q -> can_tx_ack input
            can_tx_ack <= can_tx_ack_q;
        end
    end
endmodule