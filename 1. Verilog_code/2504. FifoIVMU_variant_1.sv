//SystemVerilog
module FifoIVMU_AXIS #(parameter DEPTH = 4, parameter ADDR_W = 32) (
    input clk, rst,
    input [7:0] new_irq, // Input trigger for new data
    // AXI-Stream Output Interface
    output m_axis_tvalid,
    input m_axis_tready,
    output [ADDR_W-1:0] m_axis_tdata
);
    localparam PTR_W = $clog2(DEPTH) + 1;

    reg [ADDR_W-1:0] vector_fifo [0:DEPTH-1];
    reg [ADDR_W-1:0] vector_table [0:7];
    reg [PTR_W-1:0] wr_ptr, rd_ptr;
    wire empty, full;
    integer i; // Used for initial block and combinatorial loop

    // FIFO status logic
    // Empty when read and write pointers are the same
    assign empty = (wr_ptr == rd_ptr);
    // Full when pointers have the same lower bits but different wrap bit
    assign full = (wr_ptr[PTR_W-2:0] == rd_ptr[PTR_W-2:0]) &&
                  (wr_ptr[PTR_W-1] != rd_ptr[PTR_W-1]);

    // AXI-Stream Output Logic
    // TVALID is high when FIFO is not empty
    assign m_axis_tvalid = ~empty;
    // TDATA is the data at the read pointer
    assign m_axis_tdata = vector_fifo[rd_ptr[$clog2(DEPTH)-1:0]];

    // Logic to handle new_irq inputs and determine write enable/data
    wire write_en;
    wire [ADDR_W-1:0] data_to_write;
    wire [7:0] write_irq_index;

    // Determine if any new_irq is active and find the highest index (priority)
    // This combinatorial block implements a priority encoder (highest index wins)
    reg [7:0] highest_irq_index_reg;
    reg write_requested_reg;
    always @* begin
      highest_irq_index_reg = 0; // Default index if no IRQ is active
      write_requested_reg = 1'b0;
      // Iterate from lowest index up. The last assignment to highest_irq_index_reg
      // where new_irq[i] is true determines the index. This matches the original
      // code's implicit priority where the highest index wins due to loop order.
      for (i = 0; i < 8; i = i + 1) begin
        if (new_irq[i]) begin
          highest_irq_index_reg = i;
          write_requested_reg = 1'b1; // A write is requested by at least one IRQ
        end
      end
    end
    assign write_irq_index = highest_irq_index_reg;
    assign write_en = write_requested_reg && !full; // Actual write enable considering FIFO full

    // Data to write comes from the vector table based on the selected IRQ index
    assign data_to_write = vector_table[write_irq_index];


    // Vector table initialization
    initial begin
        for (i = 0; i < 8; i = i + 1)
            vector_table[i] = 32'h3000_0000 + (i << 3);
    end

    // Main sequential logic for FIFO pointers and memory
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            // Write operation: Triggered by new_irq if not full
            if (write_en) begin
                // Write data to the FIFO at the write pointer location
                vector_fifo[wr_ptr[$clog2(DEPTH)-1:0]] <= data_to_write;
                // Increment write pointer using standard addition
                wr_ptr <= wr_ptr + 1;
            end

            // Read operation: Triggered by AXI-Stream handshake if not empty
            // Read pointer increments only when data is consumed by the sink
            if (m_axis_tvalid && m_axis_tready) begin
                // Increment read pointer using standard addition
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    // The manchester_adder_8bit module is removed as standard addition is used for PPA optimization.

endmodule