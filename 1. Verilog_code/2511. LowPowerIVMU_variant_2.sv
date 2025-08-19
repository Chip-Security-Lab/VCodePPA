//SystemVerilog
// SystemVerilog
module LowPowerIVMU_pipelined (
    input logic main_clk,
    input logic rst_n,
    input logic [15:0] int_sources,
    input logic [15:0] int_mask,
    input logic clk_en,
    output logic [31:0] vector_out,
    output logic int_pending
);

    // Internal memory for vectors
    logic [31:0] vectors [0:15];
    integer i;

    // Initialize memory
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            vectors[i] = 32'h9000_0000 + (i * 4);
        end
    end

    // --- Pipeline Stages ---

    // Clock gating signal for low power operation
    // Pipeline registers are clocked by this gated clock
    logic gated_clk;
    // Clock is enabled if clk_en is high OR if there's any pending interrupt at the input stage
    logic s0_any_pending; // Calculated in Stage 0

    assign gated_clk = main_clk & (clk_en | s0_any_pending);

    // Stage 0: Input Processing (Combinational)
    // Calculate pending interrupts and whether any interrupt is pending
    logic [15:0] s0_pending_status;

    assign s0_pending_status = int_sources & ~int_mask;
    assign s0_any_pending    = |s0_pending_status;

    // Stage 1: Register Stage 0 outputs (Registered by gated_clk)
    // Capture the pending status for the next stage
    logic [15:0] s1_pending_status;
    logic s1_any_pending; // Propagates validity through pipeline

    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_pending_status <= 16'h0;
            s1_any_pending    <= 1'b0;
        end else begin
            s1_pending_status <= s0_pending_status;
            s1_any_pending    <= s0_any_pending;
        end
    end

    // Stage 2: Priority Encoding (Combinational)
    // Determine the index of the highest priority pending interrupt from Stage 1
    logic [3:0] s2_vector_index;

    // Priority encoder logic: finds the MSB position
    assign s2_vector_index = s1_pending_status[15] ? 4'd15 :
                             s1_pending_status[14] ? 4'd14 :
                             s1_pending_status[13] ? 4'd13 :
                             s1_pending_status[12] ? 4'd12 :
                             s1_pending_status[11] ? 4'd11 :
                             s1_pending_status[10] ? 4'd10 :
                             s1_pending_status[9]  ? 4'd9  :
                             s1_pending_status[8]  ? 4'd8  :
                             s1_pending_status[7]  ? 4'd7  :
                             s1_pending_status[6]  ? 4'd6  :
                             s1_pending_status[5]  ? 4'd5  :
                             s1_pending_status[4]  ? 4'd4  :
                             s1_pending_status[3]  ? 4'd3  :
                             s1_pending_status[2]  ? 4'd2  :
                             s1_pending_status[1]  ? 4'd1  :
                             s1_pending_status[0]  ? 4'd0  :
                             4'd0; // Default index if no interrupt is pending (handled by s1_any_pending)

    // Stage 3: Register Stage 2 outputs and propagate validity (Registered by gated_clk)
    // Capture the interrupt index and validity for the memory access stage
    logic [3:0] s3_vector_index;
    logic s3_data_valid; // Propagate the enable signal indicating valid data

    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            s3_vector_index <= 4'h0;
            s3_data_valid   <= 1'b0;
        end else begin
            // The index is registered regardless, but its validity is tracked by s3_data_valid
            s3_vector_index <= s2_vector_index;
            // s1_any_pending indicates if s1_pending_status was non-zero, signaling a valid request
            s3_data_valid   <= s1_any_pending;
        end
    end

    // Stage 4: Memory Read (Combinational)
    // Access the vector memory using the registered index from Stage 3
    logic [31:0] s4_vector_data;

    // Memory access is combinational based on the registered address s3_vector_index
    assign s4_vector_data = vectors[s3_vector_index];

    // Stage 5: Register Stage 4 outputs and Final Output (Registered by gated_clk)
    // Register the final vector data and the delayed pending status
    logic [31:0] s5_vector_out;
    logic s5_int_pending; // Final output int_pending, delayed from s0_any_pending

    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            s5_vector_out  <= 32'h0;
            s5_int_pending <= 1'b0;
        end else begin
            // s5_vector_out loads new data only if the data arriving from Stage 4 is valid
            // Validity is indicated by s3_data_valid (which came from s1_any_pending, from s0_any_pending)
            if (s3_data_valid) begin
                s5_vector_out <= s4_vector_data;
            end
            // s5_int_pending tracks the delayed any_pending signal from the input stage
            s5_int_pending <= s3_data_valid; // s3_data_valid is s0_any_pending delayed by 2 stages (S1, S3)
                                             // Registering it here adds the 3rd stage delay (S5)
        end
    end

    // Assign final outputs from the last pipeline stage registers
    assign vector_out  = s5_vector_out;
    assign int_pending = s5_int_pending;

endmodule