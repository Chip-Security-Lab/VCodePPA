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
    // Internal signals
    reg can_tx_ack;
    localparam integer SELECT_WIDTH = (NUM_MAILBOXES > 1) ? $clog2(NUM_MAILBOXES) : 1;
    reg [SELECT_WIDTH-1:0] mailbox_select;

    reg [NUM_MAILBOXES-1:0] tx_active_array;

    reg [DATA_WIDTH-1:0] tx_reg_array [0:NUM_MAILBOXES-1];
    reg [DATA_WIDTH-1:0] rx_reg_array [0:NUM_MAILBOXES-1];

    // Mailbox TX logic and RX data assignment
    genvar i;
    generate
        for (i=0; i<NUM_MAILBOXES; i=i+1) begin : mailbox_gen
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    tx_reg_array[i] <= 0;
                    tx_active_array[i] <= 0;
                    tx_complete[i] <= 0;
                end else begin
                    if (tx_request[i]) begin
                        tx_reg_array[i] <= tx_data[i];
                        tx_active_array[i] <= 1'b1;
                        tx_complete[i] <= 1'b0; // Clear complete when requesting new data
                    end else if (can_tx_ack && tx_active_array[i]) begin
                        tx_active_array[i] <= 1'b0;
                        tx_complete[i] <= 1'b1;
                    end else begin
                         tx_complete[i] <= 1'b0; // Clear complete otherwise
                    end
                    // Removed: rx_reg_array update logic was here
                end
            end

            // Assign rx_data output from internal register
            assign rx_data[i] = rx_reg_array[i];
        end
    endgenerate

    // Dedicated RX data shift register update logic
    // This block replaces the comparison chain inside the generate loop for RX updates.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all rx_reg_array elements
            for (int j=0; j<NUM_MAILBOXES; j=j+1) begin
                rx_reg_array[j] <= 0;
            end
        end else begin
            // Update the selected rx_reg_array element using mailbox_select as index
            // This avoids NUM_MAILBOXES parallel comparators (mailbox_select == i)
            // Check bounds for robustness, although arbiter should keep mailbox_select valid
            if (mailbox_select < NUM_MAILBOXES) begin
                 rx_reg_array[mailbox_select] <= {rx_reg_array[mailbox_select][DATA_WIDTH-2:0], can_rx};
            end
        end
    end


    // Simple arbitration and data multiplexing logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mailbox_select <= 0;
            can_tx <= 1'b1; // Assuming idle bus is recessive (high)
            can_tx_ack <= 1'b0;
        end else begin
            // Round-robin mailbox selection based on original condition
            // Condition: Advance if not all mailboxes are active (!(&tx_active_array))
            if (!(&tx_active_array)) begin
                if (mailbox_select == NUM_MAILBOXES - 1) begin
                    mailbox_select <= 0;
                end else begin
                    mailbox_select <= mailbox_select + 1;
                end
            end

            // Send selected mailbox data (MSB)
            can_tx <= tx_reg_array[mailbox_select][DATA_WIDTH-1];

            // Simulated ACK logic (original behavior)
            can_tx_ack <= (mailbox_select == 0);
        end
    end

endmodule