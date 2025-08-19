//SystemVerilog
module MemMappedIVMU (
    input wire clk, rst_n,
    input wire [7:0] addr,
    input wire [31:0] wdata,
    // Valid-Ready interface for memory access
    input wire wr_valid,
    output wire wr_ready, // Indicates module is ready to accept write request
    input wire rd_valid,
    output wire rd_ready, // Indicates module is ready to accept read request
    output reg [31:0] rdata, // Registered read data output
    output reg rdata_valid, // Indicates rdata is valid
    input wire rdata_ready, // Consumer is ready to accept rdata
    // Original interrupt interface (keeping as is)
    input wire [15:0] irq_sources,
    output reg [31:0] irq_vector,
    output reg irq_valid
);
    reg [31:0] regs [0:17]; // 0-15: Vector table, 16: Mask, 17: Status
    wire [15:0] masked_irq;
    integer i;

    // Internal registers for read data pipeline
    reg [31:0] read_data_reg;
    reg read_valid_q; // Registered version of read_valid state

    // For a simple register file with a 1-cycle read pipeline,
    // the module is generally ready to accept a new request.
    // A more complex module might add back-pressure here.
    assign wr_ready = 1; // Always ready for write
    assign rd_ready = 1; // Always ready for read request input

    assign masked_irq = irq_sources & ~regs[16][15:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset registers
            for (i = 0; i < 18; i = i + 1) regs[i] <= 0;

            // Reset read pipeline state
            read_data_reg <= 0;
            read_valid_q <= 0;
            rdata <= 0;
            rdata_valid <= 0;

            // Reset interrupt outputs
            irq_valid <= 0;
            irq_vector <= 0;
        end else begin
            // --- Memory Access Logic with Valid-Ready Handshake ---

            // Write Operation
            // Write happens when valid and ready are high
            if (wr_valid && wr_ready) begin
                // Assuming addr[4:0] is the intended address range (0-31)
                regs[addr[4:0]] <= wdata;
            end

            // Read Operation (Request Side)
            // When a read request is accepted, latch the data and signal validity for the pipeline
            if (rd_valid && rd_ready) begin
                 // Assuming addr[4:0] is the intended address range
                read_data_reg <= regs[addr[4:0]];
                read_valid_q <= 1; // Data will be available in the next cycle
            end

            // Read Operation (Response Side)
            // rdata_valid indicates data is ready on rdata
            // rdata_ready indicates consumer accepted the data
            // The read_valid_q state machine:
            // - Set to 1 when a read request is accepted (handled above)
            // - Cleared to 0 when the data is consumed (rdata_valid && rdata_ready)
            if (rdata_valid && rdata_ready) begin
                 read_valid_q <= 0; // Clear validity flag once consumed
            end
            // Note: If a new read request arrives before the previous data is consumed,
            // read_valid_q is set back to 1 by the 'if (rd_valid && rd_ready)' block,
            // and read_data_reg is updated. This is correct behavior for overwriting pending data.


            // Update registered outputs from pipeline registers
            rdata <= read_data_reg;
            rdata_valid <= read_valid_q;


            // --- Interrupt Logic (Original Behavior) ---
            // irq_valid is asserted if any masked interrupt is pending.
            // irq_vector provides the vector for the highest priority pending interrupt.
            // This part is kept as a simple output, not part of a handshake,
            // as the prompt focused on the request-response (memory) interface.
            irq_valid <= |masked_irq;
            irq_vector <= 0; // Default value
            // Priority encoder for irq_vector (highest bit wins)
            for (i = 15; i >= 0; i = i - 1) begin
                if (masked_irq[i]) begin
                    irq_vector <= regs[i]; // Assign vector from table
                    // The loop structure implements priority
                end
            end

            // --- Status Register Update ---
            // Update status register with current masked interrupts
            regs[17] <= {16'h0, masked_irq};
        end
    end
endmodule