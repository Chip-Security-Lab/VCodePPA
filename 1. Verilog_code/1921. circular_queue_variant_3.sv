//SystemVerilog
module circular_queue #(
    parameter DW = 8,
    parameter DEPTH = 16
) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire                en,
    input  wire [DW-1:0]       data_in,
    output reg  [DW-1:0]       data_out,
    output reg                 full,
    output reg                 empty
);

    localparam PTR_WIDTH = $clog2(DEPTH);

    reg [DW-1:0]               mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0]        rd_ptr, wr_ptr;
    reg [PTR_WIDTH:0]          queue_count;

    // Precompute next pointer values and status flags for path balancing
    wire [PTR_WIDTH-1:0]       next_rd_ptr = (rd_ptr == DEPTH-1) ? {PTR_WIDTH{1'b0}} : rd_ptr + 1'b1;
    wire [PTR_WIDTH-1:0]       next_wr_ptr = (wr_ptr == DEPTH-1) ? {PTR_WIDTH{1'b0}} : wr_ptr + 1'b1;

    wire                       queue_full  = (queue_count == DEPTH);
    wire                       queue_empty = (queue_count == 0);

    // Compute conditions for enqueue and dequeue for balanced logic depth
    wire                       can_enqueue = en & ~queue_full;
    wire                       can_dequeue = en & ~queue_empty;

    // Conditional sum-subtract for next_count calculation (conditional add-subtract algorithm)
    wire [PTR_WIDTH:0]         sum_temp;
    wire [PTR_WIDTH:0]         sub_temp;
    wire [PTR_WIDTH:0]         next_count_conditional;

    assign sum_temp = queue_count + {{(PTR_WIDTH){1'b0}}, can_enqueue};
    assign sub_temp = queue_count + (~can_dequeue + 1'b1); // Two's complement subtraction

    assign next_count_conditional = (can_enqueue && !can_dequeue) ? sum_temp :
                                    ((!can_enqueue && can_dequeue) ? sub_temp : queue_count);

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr      <= {PTR_WIDTH{1'b0}};
            wr_ptr      <= {PTR_WIDTH{1'b0}};
            queue_count <= {(PTR_WIDTH+1){1'b0}};
            data_out    <= {DW{1'b0}};
            full        <= 1'b0;
            empty       <= 1'b1;
        end else begin
            // Enqueue operation
            if (can_enqueue) begin
                mem[wr_ptr] <= data_in;
                wr_ptr      <= next_wr_ptr;
            end

            // Dequeue operation
            if (can_dequeue) begin
                data_out <= mem[rd_ptr];
                rd_ptr   <= next_rd_ptr;
            end

            // Update count, full, and empty using conditional sum-subtract
            queue_count <= next_count_conditional;
            full        <= (next_count_conditional == DEPTH);
            empty       <= (next_count_conditional == 0);
        end
    end

endmodule