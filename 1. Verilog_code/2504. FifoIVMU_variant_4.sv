//SystemVerilog
module FifoIVMU #(parameter DEPTH = 4, parameter ADDR_W = 32) (
    input clk, rst,
    input [7:0] new_irq,
    input ack,
    output [ADDR_W-1:0] curr_vector,
    output has_pending
);

    // Local parameter for pointer width (index into FIFO memory)
    localparam PTR_W = $clog2(DEPTH);

    // FIFO memory and vector table (ROM)
    reg [ADDR_W-1:0] vector_fifo [0:DEPTH-1];
    reg [ADDR_W-1:0] vector_table [0:7]; // ROM for vectors

    // Write and read pointers (PTR_W+1 bits wide for full/empty logic)
    reg [PTR_W:0] wr_ptr, rd_ptr;

    integer i; // Used only in initial block

    // Initialize vector_table (ROM) - this is accessed combinatorially later
    initial begin
        for (i = 0; i < 8; i = i + 1)
            vector_table[i] = 32'h3000_0000 + (i << 3);
    end

    // FIFO status flags (combinational logic)
    wire empty;
    wire full;

    // empty is true when write and read pointers are equal
    assign empty = (wr_ptr == rd_ptr);

    // full is true when the lower bits of pointers are equal, but MSBs are different
    // This is a common technique for power-of-2 FIFOs to distinguish full from empty
    assign full = (wr_ptr[PTR_W-1:0] == rd_ptr[PTR_W-1:0]) && (wr_ptr[PTR_W] != rd_ptr[PTR_W]);

    // has_pending is simply the inverse of empty
    assign has_pending = ~empty;

    // curr_vector is the data at the read pointer, or 0 if empty
    // This is a combinational read path from the FIFO memory
    assign curr_vector = empty ? {ADDR_W{1'b0}} : vector_fifo[rd_ptr[PTR_W-1:0]];

    // Combinational logic for write request arbitration and data lookup
    // This block determines if a write should occur and what data to write
    reg [2:0] first_irq_idx_comb; // Index of the highest priority active IRQ
    reg irq_detected_comb;        // Flag indicating if any IRQ is active
    reg [ADDR_W-1:0] data_to_write_comb; // Data to be written to the FIFO

    always @(*) begin
        irq_detected_comb = 0;
        first_irq_idx_comb = 0; // Default value
        data_to_write_comb = {ADDR_W{1'b0}}; // Default value

        // Priority encoder for new_irq (index 0 has highest priority based on original loop order)
        if (new_irq[0]) begin
            irq_detected_comb = 1;
            first_irq_idx_comb = 0;
        end else if (new_irq[1]) begin
            irq_detected_comb = 1;
            first_irq_idx_comb = 1;
        end else if (new_irq[2]) begin
            irq_detected_comb = 1;
            first_irq_idx_comb = 2;
        end else if (new_irq[3]) begin
            irq_detected_comb = 1;
            first_irq_idx_comb = 3;
        end else if (new_irq[4]) begin
            irq_detected_comb = 1;
            first_irq_idx_comb = 4;
        end else if (new_irq[5]) begin
            irq_detected_comb = 1;
            first_irq_idx_comb = 5;
        end else if (new_irq[6]) begin
            irq_detected_comb = 1;
            first_irq_idx_comb = 6;
        end else if (new_irq[7]) begin
            irq_detected_comb = 1;
            first_irq_idx_comb = 7;
        end

        // Lookup data from vector_table based on the selected IRQ index
        // This is combinational access to the ROM.
        // Only lookup if an IRQ was detected to avoid accessing vector_table with a potentially uninitialized index
        // when no IRQ is active.
        if (irq_detected_comb) begin
             data_to_write_comb = vector_table[first_irq_idx_comb];
        end
    end

    // Sequential block for pointer updates and memory write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset pointers to 0
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            reg write_en;
            // Determine if a write should occur this cycle
            // A write occurs if an IRQ is detected AND the FIFO is not full
            write_en = irq_detected_comb && !full;

            if (write_en) begin
                // Write data to the FIFO memory at the current write pointer index
                vector_fifo[wr_ptr[PTR_W-1:0]] <= data_to_write_comb;
                // Increment write pointer
                wr_ptr <= wr_ptr + 1;
            end

            // Determine if a read should occur this cycle
            // A read occurs if ack is asserted AND the FIFO is not empty
            if (ack && !empty) begin
                // Increment read pointer
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

endmodule