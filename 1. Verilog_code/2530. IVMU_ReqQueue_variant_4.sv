//SystemVerilog
// Top level module for the Request Queue
// This module instantiates the core queue logic submodule
module IVMU_ReqQueue #(parameter DEPTH=4) (
    input clk,        // Clock signal
    input rd_en,      // Read enable (dequeue operation)
    input [7:0] irq,  // Input request data (enqueue data)
    output [7:0] next_irq // Output the data at the front of the queue
);

    // Internal signals to control the core queue submodule
    // When rd_en is low, enqueue is enabled (write operation)
    wire enqueue_en = ~rd_en;
    // When rd_en is high, dequeue is enabled (read operation and shift)
    wire dequeue_en = rd_en;

    // Wire to connect the output of the core queue submodule to the top-level output
    wire [7:0] core_next_irq;

    // Instantiate the core queue logic submodule
    // This submodule handles the actual storage and shifting of the queue elements
    QueueCore #(
        .DEPTH(DEPTH),      // Pass the queue depth parameter
        .DATA_WIDTH(8)      // Specify the data width (8 bits for irq)
    ) core_queue_inst (
        .clk(clk),              // Connect clock
        .enqueue(enqueue_en),   // Connect enqueue control signal
        .dequeue(dequeue_en),   // Connect dequeue control signal
        .data_in(irq),          // Connect input request data
        .data_out(core_next_irq) // Connect the submodule output (front element)
    );

    // Connect the output from the core queue submodule to the top-level module output
    assign next_irq = core_next_irq;

endmodule

// Core logic for the Request Queue
// Implements a shift-register based queue storage and operations
module QueueCore #(parameter DEPTH=4, parameter DATA_WIDTH=8) (
    input clk,        // Clock signal
    input enqueue,    // Assert to perform an enqueue operation
    input dequeue,    // Assert to perform a dequeue operation
    input [DATA_WIDTH-1:0] data_in,  // Data to be enqueued
    output [DATA_WIDTH-1:0] data_out // Data at the front of the queue (index 0)
);

    // Internal storage for the queue elements
    // This is a register array representing the queue
    reg [DATA_WIDTH-1:0] queue [0:DEPTH-1];
    integer i; // Loop variable for shifting operations

    // Sequential logic to update the queue state on the positive clock edge
    always @(posedge clk) begin
        if (dequeue) begin
            // Dequeue operation: Shift all elements down by one position
            // The element at index 0 is effectively removed (though it's read combinatorially)
            // The last element becomes zero (or some default value)
            for (i = 0; i < DEPTH-1; i = i + 1) begin
                queue[i] <= queue[i+1];
            end
            // Clear the last element after shifting
            queue[DEPTH-1] <= {DATA_WIDTH{1'b0}};
        end else if (enqueue) begin
            // Enqueue operation: Shift all elements up by one position
            // The new data_in is inserted at the front (index 0)
            for (i = DEPTH-1; i > 0; i = i - 1) begin
                queue[i] <= queue[i-1];
            end
            // Insert the new data at the front of the queue
            queue[0] <= data_in;
        end
        // If neither enqueue nor dequeue is asserted, the queue state remains unchanged.
    end

    // The output 'data_out' always reflects the current element at the front of the queue (index 0)
    // This output is combinational from the 'queue' register array
    assign data_out = queue[0];

endmodule