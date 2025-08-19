//SystemVerilog
// Top-level module: Parameterized Priority Queue
module prio_queue #(parameter DW=8, SIZE=4) (
    input  [DW*SIZE-1:0] data_in,
    output [DW-1:0]      data_out
);

    // Internal signals for split entries
    wire [DW-1:0] entry_array [0:SIZE-1];

    // Submodule: Data Splitter
    prio_queue_data_splitter #(.DW(DW), .SIZE(SIZE)) u_data_splitter (
        .data_in   (data_in),
        .entry_out (entry_array)
    );

    // Submodule: Priority Selector
    prio_queue_prio_selector #(.DW(DW), .SIZE(SIZE)) u_prio_selector (
        .entry_in (entry_array),
        .data_out (data_out)
    );

endmodule

// ---------------------------------------------------------------------------
// Submodule: prio_queue_data_splitter
// Function: Splits the input data bus into an array of entries
// ---------------------------------------------------------------------------
module prio_queue_data_splitter #(parameter DW=8, SIZE=4) (
    input  [DW*SIZE-1:0] data_in,
    output [DW-1:0]      entry_out [0:SIZE-1]
);
    genvar i;
    generate
        for (i = 0; i < SIZE; i = i + 1) begin : gen_entry_split
            assign entry_out[i] = data_in[(i+1)*DW-1 : i*DW];
        end
    endgenerate
endmodule

// ---------------------------------------------------------------------------
// Submodule: prio_queue_prio_selector
// Function: Selects the highest-priority non-zero entry
// Priority: Highest index has highest priority
// ---------------------------------------------------------------------------
module prio_queue_prio_selector #(parameter DW=8, SIZE=4) (
    input  [DW-1:0] entry_in [0:SIZE-1],
    output reg [DW-1:0] data_out
);

    integer k;
    reg [SIZE-1:0] valid_mask;
    reg [$clog2(SIZE)-1:0] selected_index;
    reg found;

    always @(*) begin
        // Generate a mask of which entries are non-zero
        for (k = 0; k < SIZE; k = k + 1) begin
            valid_mask[k] = |entry_in[k];
        end

        found = 1'b0;
        selected_index = {($clog2(SIZE)){1'b0}};
        // Find the highest-priority non-zero entry using a range check
        for (k = SIZE-1; k >= 0; k = k - 1) begin
            if (!found && valid_mask[k]) begin
                selected_index = k[$clog2(SIZE)-1:0];
                found = 1'b1;
            end
        end

        if (found)
            data_out = entry_in[selected_index];
        else
            data_out = {DW{1'b0}};
    end

endmodule