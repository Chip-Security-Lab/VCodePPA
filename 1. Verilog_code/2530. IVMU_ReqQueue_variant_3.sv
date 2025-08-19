//SystemVerilog
// SystemVerilog
module IVMU_ReqQueue #(parameter DEPTH=4) (
    input clk,
    input rd_en,
    input [7:0] irq,
    output reg [7:0] next_irq
);

    // State definitions
    localparam [2:0]
        STATE_IDLE          = 3'd0,
        STATE_DEQUEUE_ITER  = 3'd1,
        STATE_DEQUEUE_FINAL = 3'd2,
        STATE_ENQUEUE_ITER  = 3'd3,
        STATE_ENQUEUE_FINAL = 3'd4;

    reg [2:0] current_state, next_state;

    // Counter width required for DEPTH-1 iterations (0 to DEPTH-2 or DEPTH-1 down to 1)
    // Need to count up to DEPTH-1.
    // If DEPTH=1, max count is 0, width=1 ($clog2(1)=0, but need at least 1 bit for 0).
    // If DEPTH=2, max count is 1, width=1.
    // If DEPTH=3, max count is 2, width=2.
    // If DEPTH=4, max count is 3, width=2.
    localparam CNT_WIDTH = (DEPTH <= 2) ? 1 : $clog2(DEPTH - 1);
    reg [CNT_WIDTH-1:0] current_loop_cnt, next_loop_cnt;

    // Queue
    reg [7:0] queue [0:DEPTH-1];

    // State and counter logic
    always @(posedge clk) begin
        current_state <= next_state;
        current_loop_cnt <= next_loop_cnt;
    end

    // Next state and next counter logic (Combinational)
    always @(*) begin
        next_state = current_state;
        next_loop_cnt = current_loop_cnt;

        case (current_state)
            STATE_IDLE: begin
                if (rd_en) begin
                    if (DEPTH > 1) begin
                        next_state = STATE_DEQUEUE_ITER;
                        next_loop_cnt = {CNT_WIDTH{1'b0}}; // Start index i = 0
                    end else begin // DEPTH = 1
                        next_state = STATE_DEQUEUE_FINAL; // Skip iteration state
                        next_loop_cnt = {CNT_WIDTH{1'b0}};
                    end
                end else begin // !rd_en
                    if (DEPTH > 1) begin
                        next_state = STATE_ENQUEUE_ITER;
                        next_loop_cnt = DEPTH - 1; // Start index i = DEPTH-1
                    end else begin // DEPTH = 1
                         next_state = STATE_ENQUEUE_FINAL; // Skip iteration state
                         next_loop_cnt = {CNT_WIDTH{1'b0}};
                    end
                end
            end

            STATE_DEQUEUE_ITER: begin
                // Loop condition: i < DEPTH-1 (i goes from 0 to DEPTH-2)
                // We are in iteration 'current_loop_cnt'
                if (current_loop_cnt < DEPTH - 2) begin // Not the last iteration (i < DEPTH-2)
                    next_loop_cnt = current_loop_cnt + 1;
                    next_state = STATE_DEQUEUE_ITER;
                end else if (current_loop_cnt == DEPTH - 2) begin // The last iteration (i == DEPTH-2)
                    next_loop_cnt = current_loop_cnt + 1; // Counter becomes DEPTH-1
                    next_state = STATE_DEQUEUE_FINAL;
                end else begin // Should not happen if DEPTH > 1 and logic is correct
                    next_state = STATE_IDLE; // Error or unexpected state
                end
            end

            STATE_DEQUEUE_FINAL: begin
                next_state = STATE_IDLE;
                next_loop_cnt = {CNT_WIDTH{1'b0}}; // Reset counter
            end

            STATE_ENQUEUE_ITER: begin
                // Loop condition: i > 0 (i goes from DEPTH-1 down to 1)
                // We are in iteration 'current_loop_cnt'
                if (current_loop_cnt > 1) begin // Not the last iteration (i > 1)
                    next_loop_cnt = current_loop_cnt - 1;
                    next_state = STATE_ENQUEUE_ITER;
                end else if (current_loop_cnt == 1) begin // The last iteration (i == 1)
                    next_loop_cnt = current_loop_cnt - 1; // Counter becomes 0
                    next_state = STATE_ENQUEUE_FINAL;
                end else begin // Should not happen if DEPTH > 1 and logic is correct
                     next_state = STATE_IDLE; // Error or unexpected state
                end
            end

            STATE_ENQUEUE_FINAL: begin
                next_state = STATE_IDLE;
                next_loop_cnt = {CNT_WIDTH{1'b0}}; // Reset counter
            end

            default: begin
                // Undefined state, reset
                next_state = STATE_IDLE;
                next_loop_cnt = {CNT_WIDTH{1'b0}};
            end
        endcase
    end

    // Queue and Output updates (Sequential)
    always @(posedge clk) begin
        case (current_state)
            STATE_IDLE: begin
                // Output reflects queue[0] when idle
                next_irq <= queue[0];
            end

            STATE_DEQUEUE_ITER: begin
                // Perform one shift: queue[i] <= queue[i+1];
                // current_loop_cnt holds the current index 'i'
                 if (current_loop_cnt < DEPTH - 1) begin // Ensure index is valid
                    queue[current_loop_cnt] <= queue[current_loop_cnt + 1];
                 end
                 // next_irq holds its value during iterations
            end

            STATE_DEQUEUE_FINAL: begin
                // Final step after loop: queue[DEPTH-1] <= 8'h0;
                queue[DEPTH-1] <= 8'h0;
                // Update output after operation is complete
                if (DEPTH > 1)
                    next_irq <= queue[1]; // New queue[0] was old queue[1]
                else // DEPTH = 1
                    next_irq <= 8'h0; // New queue[0] is 0
            end

            STATE_ENQUEUE_ITER: begin
                // Perform one shift: queue[i] <= queue[i-1];
                // current_loop_cnt holds the current index 'i'
                if (current_loop_cnt > 0) begin // Ensure index is valid
                     queue[current_loop_cnt] <= queue[current_loop_cnt - 1];
                end
                // next_irq holds its value during iterations
            end

            STATE_ENQUEUE_FINAL: begin
                // Final step after loop: queue[0] <= irq;
                queue[0] <= irq;
                // Update output after operation is complete
                next_irq <= irq; // New queue[0] is irq
            end

            default: begin
                // In case of unexpected state, hold values or reset
                // Holding values is safer for ongoing operations
                // next_irq holds its value
            end
        endcase
    end

    // Initial state and counter reset
    initial begin
        current_state = STATE_IDLE;
        current_loop_cnt = {CNT_WIDTH{1'b0}};
        next_irq = 8'h0; // Initialize output
        // Queue contents are typically uninitialized by default
    end

endmodule