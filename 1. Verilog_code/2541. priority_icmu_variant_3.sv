//SystemVerilog
module priority_icmu #(parameter INT_WIDTH = 8, CTX_WIDTH = 32) (
    input wire clk, rst_n,
    input wire [INT_WIDTH-1:0] int_req,
    input wire [CTX_WIDTH-1:0] current_ctx,
    output reg [INT_WIDTH-1:0] int_ack,
    output reg [CTX_WIDTH-1:0] saved_ctx,
    output reg [(INT_WIDTH > 1 ? $clog2(INT_WIDTH) : 1)-1:0] int_id, // Adjusted width based on INT_WIDTH
    output reg active // Indicates when output is valid
);

    // Calculate width for int_id
    localparam INT_ID_WIDTH = (INT_WIDTH > 1) ? $clog2(INT_WIDTH) : 1;

    // Buffered reset signal
    wire rst_n_buf = rst_n;

    // State variable: Mask of processed interrupts
    reg [INT_WIDTH-1:0] int_mask;

    // Combinational logic for priority encoding
    // Finds the index of the highest set bit (highest priority)
    function [INT_ID_WIDTH-1:0] get_priority;
        input [INT_WIDTH-1:0] req;
        integer i;
        begin
            get_priority = 0; // Default value if no bits are set
            for (i = 0; i < INT_WIDTH; i = i+1) begin
                if (req[i]) begin
                    get_priority = i;
                end
            end
        end
    endfunction

    // Pipeline registers Stage 0 (Input Latch)
    reg s0_valid;
    reg [INT_WIDTH-1:0] s0_req;
    reg [CTX_WIDTH-1:0] s0_ctx;

    // Stage 0 combinational logic (Masking)
    wire [INT_WIDTH-1:0] s0_masked_req_comb;
    assign s0_masked_req_comb = s0_req & ~int_mask;

    // Pipeline registers Stage 1 (Masked Data Latch)
    reg s1_valid;
    reg [INT_WIDTH-1:0] s1_masked_req;
    reg [CTX_WIDTH-1:0] s1_ctx;

    // Stage 1 combinational logic (Priority Encoding)
    wire [INT_ID_WIDTH-1:0] s1_int_id_comb;
    assign s1_int_id_comb = get_priority(s1_masked_req);

    // Pipeline registers Stage 2 (ID Latch)
    reg s2_valid;
    reg [INT_ID_WIDTH-1:0] s2_int_id;
    reg [CTX_WIDTH-1:0] s2_ctx;

    // Stage 2 combinational logic (Output Formatting)
    wire [INT_WIDTH-1:0] s2_int_ack_comb;
    assign s2_int_ack_comb = (1'b1 << s2_int_id);

    // Stage 0: Input Latch
    // Latch new requests if int_req is asserted. No backpressure in this simple model.
    always @(posedge clk or negedge rst_n_buf) begin
        if (!rst_n_buf) begin
            s0_valid <= 1'b0;
            s0_req <= {INT_WIDTH{1'b0}};
            s0_ctx <= {CTX_WIDTH{1'b0}};
        end else begin
            if (|int_req) begin // Assume |int_req acts as input valid
                s0_valid <= 1'b1;
                s0_req <= int_req;
                s0_ctx <= current_ctx;
            end else begin
                s0_valid <= 1'b0; // No valid input this cycle
            end
        end
    end

    // Stage 1: Masked Data Latch and Priority Encoding Input
    // Propagate data from Stage 0 if it was valid
    always @(posedge clk or negedge rst_n_buf) begin
        if (!rst_n_buf) begin
            s1_valid <= 1'b0;
            s1_masked_req <= {INT_WIDTH{1'b0}};
            s1_ctx <= {CTX_WIDTH{1'b0}};
        end else begin
            if (s0_valid) begin
                s1_valid <= 1'b1;
                s1_masked_req <= s0_masked_req_comb; // Use masked request
                s1_ctx <= s0_ctx;
            end else begin
                s1_valid <= 1'b0;
            end
        end
    end

    // Stage 2: ID Latch and Output Formatting Input
    // Propagate data from Stage 1 if it was valid
    always @(posedge clk or negedge rst_n_buf) begin
        if (!rst_n_buf) begin
            s2_valid <= 1'b0;
            s2_int_id <= {INT_ID_WIDTH{1'b0}};
            s2_ctx <= {CTX_WIDTH{1'b0}};
        end else begin
            if (s1_valid) begin
                s2_valid <= 1'b1;
                s2_int_id <= s1_int_id_comb; // Use computed ID
                s2_ctx <= s1_ctx;
            end else begin
                s2_valid <= 1'b0;
            end
        end
    end

    // Output Registers
    // Update outputs when Stage 2 data is valid
    always @(posedge clk or negedge rst_n_buf) begin
        if (!rst_n_buf) begin
            int_ack <= {INT_WIDTH{1'b0}};
            saved_ctx <= {CTX_WIDTH{1'b0}};
            int_id <= {INT_ID_WIDTH{1'b0}};
        end else begin
            if (s2_valid) begin
                int_ack <= s2_int_ack_comb; // Use computed ack
                saved_ctx <= s2_ctx;
                int_id <= s2_int_id;
            end else begin
                // Outputs hold previous value or become zero when not valid?
                // Setting to zero when not valid is clearer for a pipelined output
                int_ack <= {INT_WIDTH{1'b0}};
                saved_ctx <= {CTX_WIDTH{1'b0}};
                int_id <= {INT_ID_WIDTH{1'b0}};
            end
        end
    end

    // Active Output Register
    // Indicates when the output registers contain valid data
    always @(posedge clk or negedge rst_n_buf) begin
        if (!rst_n_buf) begin
            active <= 1'b0;
        end else begin
            active <= s2_valid; // Active indicates valid data at the output stage
        end
    end

    // Interrupt Mask State Register
    // Update mask based on the interrupt ID that completes Stage 2
    always @(posedge clk or negedge rst_n_buf) begin
        if (!rst_n_buf) begin
            int_mask <= {INT_WIDTH{1'b0}};
        end else begin
            if (s2_valid) begin
                int_mask <= int_mask | s2_int_ack_comb; // Mask the processed interrupt
            end
            // int_mask holds its value if no valid request finishes Stage 2
        end
    end

endmodule