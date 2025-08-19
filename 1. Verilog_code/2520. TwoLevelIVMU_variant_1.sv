//SystemVerilog
module TwoLevelIVMU (
    input wire clock, reset,
    input wire [31:0] irq_lines,
    input wire [31:0] group_priority_flat, // This input is unused in the original logic and thus in the optimized logic
    output reg [31:0] handler_addr,
    output reg irq_active
);
    reg [31:0] vector_table [0:31];
    wire [7:0] group_pending;
    reg [3:0] active_group; // Registered output group index
    reg [3:0] active_line;  // Registered output line index

    // Calculate group interrupt pending (same as original)
    assign group_pending[0] = |irq_lines[3:0];
    assign group_pending[1] = |irq_lines[7:4];
    assign group_pending[2] = |irq_lines[11:8];
    assign group_pending[3] = |irq_lines[15:12];
    assign group_pending[4] = |irq_lines[19:16];
    assign group_pending[5] = |irq_lines[23:20];
    assign group_pending[6] = |irq_lines[27:24];
    assign group_pending[7] = |irq_lines[31:28];

    // Initialize vector table (same functionality as original, using loop)
    initial begin
        for (int i = 0; i < 32; i++) begin
            vector_table[i] = 32'hFFF8_0000 + (i << 4);
        end
    end

    // Combinational logic for priority encoding
    wire [2:0] next_active_group_idx_comb;
    wire [1:0] next_active_line_idx_comb;
    wire [31:0] next_handler_addr_comb;
    wire group_pending_any;
    wire [4:0] next_vector_index_comb;

    // Check if any interrupt is pending
    assign group_pending_any = |group_pending;

    // Priority encoder for groups (0 is highest priority)
    // Find the index of the first '1' from the LSB (0 to 7)
    assign next_active_group_idx_comb =
        group_pending[0] ? 3'd0 :
        group_pending[1] ? 3'd1 :
        group_pending[2] ? 3'd2 :
        group_pending[3] ? 3'd3 :
        group_pending[4] ? 3'd4 :
        group_pending[5] ? 3'd5 :
        group_pending[6] ? 3'd6 :
        group_pending[7] ? 3'd7 : 3'd0; // Default when no group is pending

    // Select the 4-bit slice of irq_lines for the selected group
    wire [3:0] current_group_irq_lines;
    // Use SystemVerilog slicing with variable index
    assign current_group_irq_lines = irq_lines[4*next_active_group_idx_comb +: 4];

    // Priority encoder for lines within the group (3 is highest priority)
    // Find the index of the first '1' from the MSB (0 to 3)
    assign next_active_line_idx_comb =
        current_group_irq_lines[3] ? 2'd3 :
        current_group_irq_lines[2] ? 2'd2 :
        current_group_irq_lines[1] ? 2'd1 :
        current_group_irq_lines[0] ? 2'd0 : 2'd0; // Default when no line is pending in the selected group

    // Calculate the vector table index
    assign next_vector_index_comb = (next_active_group_idx_comb << 2) | next_active_line_idx_comb;

    // Determine next handler address based on the calculated index
    assign next_handler_addr_comb = vector_table[next_vector_index_comb];

    // Registered outputs
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            irq_active <= 1'b0;
            handler_addr <= 32'b0;
            active_group <= 4'b0;
            active_line <= 4'b0;
        end else begin
            if (group_pending_any) begin
                irq_active <= 1'b1;
                handler_addr <= next_handler_addr_comb;
                // Pad smaller indices to 4 bits to match original register width
                active_group <= {1'b0, next_active_group_idx_comb};
                active_line <= {2'b0, next_active_line_idx_comb};
            end else begin
                // No interrupt pending
                irq_active <= 1'b0;
                handler_addr <= 32'b0;
                active_group <= 4'b0;
                active_line <= 4'b0;
            end
        end
    end

endmodule