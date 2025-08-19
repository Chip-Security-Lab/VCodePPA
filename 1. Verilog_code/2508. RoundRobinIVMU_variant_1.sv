//SystemVerilog
module RoundRobinIVMU (
    input clk, rst,
    input [7:0] irq,
    input ack,
    output reg [31:0] vector,
    output reg valid
);
    reg [2:0] last_served;
    reg [31:0] vector_table [0:7];
    reg [7:0] pending;

    // Initialization - Use initial block for synthesis if values are fixed
    initial begin
        vector_table[0] = 32'h6000_0000;
        vector_table[1] = 32'h6000_0020;
        vector_table[2] = 32'h6000_0040;
        vector_table[3] = 32'h6000_0060;
        vector_table[4] = 32'h6000_0080;
        vector_table[5] = 32'h6000_00A0;
        vector_table[6] = 32'h6000_00C0;
        vector_table[7] = 32'h6000_00E0;
    end

    // Combinational logic to find the next interrupt index and vector
    // This logic finds the highest priority pending interrupt based on last_served
    wire [7:0] current_pending = pending | irq; // Pending state including new requests

    // Generate the 8 candidate indices in round-robin priority order
    wire [2:0] candidate_idx [0:7];
    genvar k;
    generate
        for (k = 0; k < 7; k = k + 1) begin : gen_candidate_idx
            assign candidate_idx[k] = (last_served + k + 1) % 8;
        end
        assign candidate_idx[7] = last_served; // Lowest priority is the last served one
    endgenerate

    // Check pending status for each candidate index
    wire [7:0] candidate_pending;
    generate
        for (k = 0; k < 8; k = k + 1) begin : gen_candidate_pending
            assign candidate_pending[k] = current_pending[candidate_idx[k]];
        end
    endgenerate

    // Priority encoder: Find the first set bit in candidate_pending (highest priority)
    // Rewritten using if-else if chain for optimized comparison logic
    reg [2:0] prio_encoded_idx;
    reg prio_valid;

    always @(*) begin
        // Default assignments
        prio_encoded_idx = 3'b0;
        prio_valid = 1'b0;

        // Implement priority encoder logic using if-else if chain
        if (candidate_pending[0]) begin
            prio_encoded_idx = candidate_idx[0];
            prio_valid = 1'b1;
        end else if (candidate_pending[1]) begin
            prio_encoded_idx = candidate_idx[1];
            prio_valid = 1'b1;
        end else if (candidate_pending[2]) begin
            prio_encoded_idx = candidate_idx[2];
            prio_valid = 1'b1;
        end else if (candidate_pending[3]) begin
            prio_encoded_idx = candidate_idx[3];
            prio_valid = 1'b1;
        end else if (candidate_pending[4]) begin
            prio_encoded_idx = candidate_idx[4];
            prio_valid = 1'b1;
        end else if (candidate_pending[5]) begin
            prio_encoded_idx = candidate_idx[5];
            prio_valid = 1'b1;
        end else if (candidate_pending[6]) begin
            prio_encoded_idx = candidate_idx[6];
            prio_valid = 1'b1;
        end else if (candidate_pending[7]) begin
            prio_encoded_idx = candidate_idx[7];
            prio_valid = 1'b1;
        end
        // If none are pending, prio_valid remains 0 and prio_encoded_idx remains 3'b0 (default)
    end

    // State updates on clock edge
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            last_served <= 3'b0;
            pending <= 8'b0;
            valid <= 1'b0;
            vector <= 32'h0;
        end else begin
            reg [7:0] next_pending;
            next_pending = current_pending; // Start with pending including new IRQs

            // Clear valid flag if acknowledged
            if (ack) begin
                valid <= 1'b0;
            end

            // If valid is low and there is an interrupt found by the priority encoder
            // Check for prio_valid first to potentially short-circuit logic
            if (prio_valid && !valid) begin
                valid <= 1'b1; // Set valid flag high
                vector <= vector_table[prio_encoded_idx]; // Get the vector
                next_pending[prio_encoded_idx] = 1'b0; // Clear the served pending bit
                last_served <= prio_encoded_idx; // Update last_served to the index that was just served
            end

            // Latch the new pending state
            pending <= next_pending;
        end
    end

endmodule