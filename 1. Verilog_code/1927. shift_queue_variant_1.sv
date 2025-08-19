//SystemVerilog
module shift_queue_pipelined #(
    parameter DW=8,
    parameter DEPTH=4
) (
    input                      clk,
    input                      rst_n,
    input                      load,
    input                      shift,
    input  [DW*DEPTH-1:0]      data_in,
    input                      valid_in,
    output                     ready_out,
    output reg [DW-1:0]        data_out,
    output                     valid_out
);

    // Valid pipeline registers
    reg valid_pipeline [0:DEPTH];
    integer valid_idx;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (valid_idx=0; valid_idx<=DEPTH; valid_idx=valid_idx+1)
                valid_pipeline[valid_idx] <= 1'b0;
        end else begin
            // Simplified using distributive and absorption laws:
            // valid_pipeline[0] <= valid_in & (load | shift);
            // (A & (B | C)) = (A & B) | (A & C)
            // valid_pipeline[0] <= (valid_in & load) | (valid_in & shift);
            valid_pipeline[0] <= (valid_in & load) | (valid_in & shift);
            for (valid_idx=1; valid_idx<=DEPTH; valid_idx=valid_idx+1)
                valid_pipeline[valid_idx] <= valid_pipeline[valid_idx-1];
        end
    end
    assign valid_out = valid_pipeline[DEPTH];

    // Ready signal (always ready)
    assign ready_out = 1'b1;

    // Pipeline queue registers
    reg [DW-1:0] queue_pipeline [0:DEPTH-1][0:DEPTH-1];
    integer stage_idx, entry_idx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (stage_idx=0; stage_idx<DEPTH; stage_idx=stage_idx+1)
                for (entry_idx=0; entry_idx<DEPTH; entry_idx=entry_idx+1)
                    queue_pipeline[stage_idx][entry_idx] <= {DW{1'b0}};
        end else begin
            // (load & valid_in) and (shift & valid_in) are used multiple times, so precompute
            // Also, (load & valid_in) | (shift & valid_in) = valid_in & (load | shift)
            if (valid_in & load) begin
                // Load initial data into first stage
                for (entry_idx=0; entry_idx<DEPTH; entry_idx=entry_idx+1)
                    queue_pipeline[0][entry_idx] <= data_in[entry_idx*DW +: DW];
                // Clear downstream stages
                for (stage_idx=1; stage_idx<DEPTH; stage_idx=stage_idx+1)
                    for (entry_idx=0; entry_idx<DEPTH; entry_idx=entry_idx+1)
                        queue_pipeline[stage_idx][entry_idx] <= {DW{1'b0}};
            end else if (valid_in & shift) begin
                // Shift pipeline stages
                for (stage_idx=DEPTH-1; stage_idx>0; stage_idx=stage_idx-1) begin
                    for (entry_idx=0; entry_idx<DEPTH; entry_idx=entry_idx+1)
                        queue_pipeline[stage_idx][entry_idx] <= queue_pipeline[stage_idx-1][entry_idx];
                end
                // Stage 0: shift queue, insert zero at the front
                for (entry_idx=DEPTH-1; entry_idx>0; entry_idx=entry_idx-1)
                    queue_pipeline[0][entry_idx] <= queue_pipeline[0][entry_idx-1];
                queue_pipeline[0][0] <= {DW{1'b0}};
            end
        end
    end

    // Pipeline output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DW{1'b0}};
        end else begin
            // Using absorption: (A ? B : 0) = A & B
            data_out <= valid_pipeline[DEPTH] ? queue_pipeline[DEPTH-1][DEPTH-1] : {DW{1'b0}};
        end
    end

endmodule