//SystemVerilog
module fifo_icmu #(
    parameter INT_COUNT = 16,
    parameter FIFO_DEPTH = 8,
    parameter CTX_WIDTH = 64
)(
    input wire clk, rstn,
    input wire [INT_COUNT-1:0] int_sources,
    input wire [CTX_WIDTH-1:0] current_ctx,
    input wire service_done,
    output reg [3:0] int_id,
    output reg [CTX_WIDTH-1:0] saved_ctx,
    output reg interrupt_valid,
    output reg fifo_full, fifo_empty // These are the primary state registers and module outputs
);
    reg [3:0] id_fifo [FIFO_DEPTH-1:0];
    reg [CTX_WIDTH-1:0] ctx_fifo [FIFO_DEPTH-1:0];
    reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(FIFO_DEPTH):0] count;
    reg [INT_COUNT-1:0] last_sources;

    // Added buffer registers for high-fanout signals fifo_empty and fifo_full (derived from count)
    // These registers capture the state for use in the next cycle's logic, reducing fanout load
    reg buffered_fifo_empty;
    reg buffered_fifo_full;

    // Intermediate wires for clarity. Conditions now use the buffered signals.
    // Note: Using buffered signals introduces one cycle of latency to these conditions,
    // potentially changing cycle-accurate behavior compared to the original code.
    wire pop_condition_met = service_done & ~buffered_fifo_empty;
    wire present_output_condition = ~buffered_fifo_empty & (~interrupt_valid | service_done);
    // Derived condition for invalidating output using Boolean analysis of original else if
    wire invalidate_output_condition = service_done & buffered_fifo_empty;


    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            last_sources <= 0;
            interrupt_valid <= 0;
            fifo_empty <= 1; // Primary state register reset
            fifo_full <= 0;  // Primary state register reset
            // Reset buffer registers
            buffered_fifo_empty <= 1;
            buffered_fifo_full <= 0;
        end else begin
            // --- State Updates (using original signals where necessary for correct state transitions) ---

            // Detect new interrupts and push if not full
            // Loop condition now uses buffered_fifo_full to reduce fanout on fifo_full register
            for (integer i = 0; i < INT_COUNT; i = i+1) begin
                // Simplified boolean expression for push condition per source
                // Uses buffered_fifo_full
                if (int_sources[i] & ~last_sources[i] & ~buffered_fifo_full) begin
                    id_fifo[wr_ptr] <= i[3:0];
                    ctx_fifo[wr_ptr] <= current_ctx;
                    // These updates within the loop match original code's behavior
                    wr_ptr <= (wr_ptr == FIFO_DEPTH-1) ? 0 : wr_ptr + 1;
                    count <= count + 1;
                end
            end

            // Service completion (FIFO read)
            // Condition uses buffered_fifo_empty via pop_condition_met
            if (pop_condition_met) begin // Using intermediate wire which uses buffered_fifo_empty
                rd_ptr <= (rd_ptr == FIFO_DEPTH-1) ? 0 : rd_ptr + 1;
                count <= count - 1;
            end

            // Update primary state flags (fifo_empty, fifo_full) based on current count
            // These updates feed the buffer registers in the next cycle
            last_sources <= int_sources;
            fifo_empty <= (count == 0); // Primary state register update
            fifo_full <= (count == FIFO_DEPTH); // Primary state register update

            // Present interrupt / Update interrupt_valid
            // Conditions use buffered_fifo_empty
            if (present_output_condition) begin // Using intermediate wire which uses buffered_fifo_empty
                int_id <= id_fifo[rd_ptr];
                saved_ctx <= ctx_fifo[rd_ptr];
                interrupt_valid <= 1;
            end else if (invalidate_output_condition) begin // Using explicitly derived condition which uses buffered_fifo_empty
                interrupt_valid <= 0;
            end
            // else interrupt_valid holds its value

            // --- Register Buffers Update ---
            // Buffer the primary state register values for use in the *next* cycle's logic
            buffered_fifo_empty <= fifo_empty;
            buffered_fifo_full <= fifo_full;

        end // else !rstn
    end // always

endmodule