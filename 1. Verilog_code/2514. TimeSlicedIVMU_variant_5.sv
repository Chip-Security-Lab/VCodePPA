//SystemVerilog
module TimeSlicedIVMU (
    input clk,
    input rst,
    input [15:0] irq_in,
    input [3:0] time_slice,
    input ack_in,           // Req-Ack: acknowledge input from receiver
    output [31:0] vector_addr, // Req-Ack: data output
    output req_out          // Req-Ack: request output (indicates valid data available)
);

    // Internal memory for vector table
    reg [31:0] vector_table [0:15];
    integer i; // Used only in initial block

    // Initialise vector table
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            vector_table[i] = 32'hC000_0000 + (i << 6);
        end
    end

    // Mask IRQ input based on time slice
    wire [15:0] slice_masked;
    assign slice_masked = irq_in & (16'h1 << time_slice);

    // Combinatorial logic to calculate the *next* potential output values
    wire next_req_out; // Potential request signal based on current inputs
    wire [31:0] calculated_vector_addr; // Potential vector address based on current inputs

    // A request is generated if any bit in the masked slice is high
    assign next_req_out = |slice_masked;

    // Combinatorial priority encoder for vector_addr
    // This logic determines the address corresponding to the highest set bit in slice_masked
    assign calculated_vector_addr = next_req_out ? ( // Only calculate if a request is potentially needed
        slice_masked[15] ? vector_table[15] :
        slice_masked[14] ? vector_table[14] :
        slice_masked[13] ? vector_table[13] :
        slice_masked[12] ? vector_table[12] :
        slice_masked[11] ? vector_table[11] :
        slice_masked[10] ? vector_table[10] :
        slice_masked[9]  ? vector_table[9]  :
        slice_masked[8]  ? vector_table[8]  :
        slice_masked[7]  ? vector_table[7]  :
        slice_masked[6]  ? vector_table[6]  :
        slice_masked[5]  ? vector_table[5]  :
        slice_masked[4]  ? vector_table[4]  :
        slice_masked[3]  ? vector_table[3]  :
        slice_masked[2]  ? vector_table[2]  :
        slice_masked[1]  ? vector_table[1]  :
        slice_masked[0]  ? vector_table[0]  :
        // This case should theoretically not be reached if next_req_out is 1,
        // but provide a default for completeness.
        32'h0
    ) : 32'h0; // If no masked IRQ, the data is not valid (req_out will be 0)

    // Registered outputs implementing the Req-Ack handshake protocol
    reg [31:0] vector_addr_reg; // Holds the data while req_out is high
    reg req_out_reg; // Controls the request signal state

    // Sequential logic for the Req-Ack handshake state and output registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset outputs to default/idle state
            vector_addr_reg <= 32'h0;
            req_out_reg <= 1'b0;
        end else begin
            // Determine if the output registers should update based on handshake state and next data availability
            // Update occurs if:
            // 1. The module is currently idle (req_out_reg is low).
            // 2. The module is currently requesting (req_out_reg is high) AND the receiver acknowledges (ack_in is high).
            // This condition can be written as: (!req_out_reg) || (req_out_reg && ack_in)
            // Which simplifies to: (!req_out_reg) || ack_in
            if (!req_out_reg || ack_in) begin
                // If idle, or previous request was acknowledged, load the new calculated values
                vector_addr_reg <= calculated_vector_addr;
                req_out_reg <= next_req_out;
            end else begin
                // If req_out_reg is high and ack_in is low, hold the current output values
                // (Implicitly done by not assigning in this branch)
                // vector_addr_reg <= vector_addr_reg;
                // req_out_reg <= req_out_reg;
            end
        end
    end

    // Assign the registered outputs to the module ports
    assign vector_addr = vector_addr_reg;
    assign req_out = req_out_reg;

endmodule