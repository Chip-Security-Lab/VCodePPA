//SystemVerilog
module FifoIVMU #(parameter DEPTH = 4, parameter ADDR_W = 32) (
    input clk, rst,
    input [7:0] new_irq,
    input ack,
    output [ADDR_W-1:0] curr_vector,
    output has_pending
);
    // Calculate address width for internal pointers
    localparam PTR_W = $clog2(DEPTH) + 1;
    localparam ADDR_IDX_W = $clog2(DEPTH);

    reg [ADDR_W-1:0] vector_fifo [0:DEPTH-1];
    reg [ADDR_W-1:0] vector_table [0:7]; // Initialized once
    
    // Pointer registers
    reg [PTR_W-1:0] wr_ptr;
    reg [PTR_W-1:0] rd_ptr;

    // Registered inputs to reduce fanout on combinatorial logic
    reg [7:0] new_irq_reg;
    reg ack_reg;

    // Combinatorial empty/full signals (intermediate)
    wire empty_comb;
    wire full_comb;

    // Registered versions of empty/full for control logic (buffer registers for high fanout)
    reg empty_reg;
    reg full_reg;

    // Registered read address for accessing memory (pipelines read)
    reg [ADDR_IDX_W-1:0] rd_addr_reg;

    // Registered output data (pipelines read)
    reg [ADDR_W-1:0] curr_vector_reg;

    // Registered has_pending (derived from registered empty)
    reg has_pending_reg;

    // Initialize vector_table (combinatorial/initial block)
    initial begin
        vector_table[0] = 32'h3000_0000 + (0 << 3);
        vector_table[1] = 32'h3000_0000 + (1 << 3);
        vector_table[2] = 32'h3000_0000 + (2 << 3);
        vector_table[3] = 32'h3000_0000 + (3 << 3);
        vector_table[4] = 32'h3000_0000 + (4 << 3);
        vector_table[5] = 32'h3000_0000 + (5 << 3);
        vector_table[6] = 32'h3000_0000 + (6 << 3);
        vector_table[7] = 32'h3000_0000 + (7 << 3);
    end

    // Register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            new_irq_reg <= 0;
            ack_reg <= 0;
        end else begin
            new_irq_reg <= new_irq;
            ack_reg <= ack;
        end
    end

    // Combinatorial empty and full logic
    // These are derived from the pointer registers
    assign empty_comb = (wr_ptr == rd_ptr);
    assign full_comb = (wr_ptr[ADDR_IDX_W-1:0] == rd_ptr[ADDR_IDX_W-1:0]) && 
                       (wr_ptr[PTR_W-1] != rd_ptr[PTR_W-1]); // Compare MSB for wrap-around

    // Register empty and full to buffer their fanout to control logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            empty_reg <= 1'b1;
            full_reg <= 1'b0;
        end else begin
            empty_reg <= empty_comb;
            full_reg <= full_comb;
        end
    end
    
    // Register read address for accessing memory in the next cycle
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_addr_reg <= 0;
        end else begin
            // Register the current read pointer index
            rd_addr_reg <= rd_ptr[ADDR_IDX_W-1:0]; 
        end
    end

    // Register output data (read from memory using registered address)
    // This introduces one cycle of read latency
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            curr_vector_reg <= 0;
        end else begin
            // Read from memory using the registered address
            curr_vector_reg <= vector_fifo[rd_addr_reg];
        end
    end

    // Register has_pending status (derived from registered empty)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            has_pending_reg <= 1'b0;
        end else begin
            has_pending_reg <= ~empty_reg;
        end
    end

    // Main pointer update logic (uses registered inputs and registered empty/full)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0; 
            rd_ptr <= 0;
        end else begin
            // Temporary variable to calculate the next write pointer value based on inputs
            reg [PTR_W-1:0] current_wr_ptr_state;
            current_wr_ptr_state = wr_ptr; // Start calculation from current wr_ptr

            // Write logic: Unrolled iteration through new_irq_reg bits
            // Process bit 0
            if (new_irq_reg[0] && !full_reg) begin
                vector_fifo[current_wr_ptr_state[ADDR_IDX_W-1:0]] <= vector_table[0];
                current_wr_ptr_state = current_wr_ptr_state + 1;
            end
            
            // Process bit 1
            if (new_irq_reg[1] && !full_reg) begin
                vector_fifo[current_wr_ptr_state[ADDR_IDX_W-1:0]] <= vector_table[1];
                current_wr_ptr_state = current_wr_ptr_state + 1;
            end

            // Process bit 2
            if (new_irq_reg[2] && !full_reg) begin
                vector_fifo[current_wr_ptr_state[ADDR_IDX_W-1:0]] <= vector_table[2];
                current_wr_ptr_state = current_wr_ptr_state + 1;
            end

            // Process bit 3
            if (new_irq_reg[3] && !full_reg) begin
                vector_fifo[current_wr_ptr_state[ADDR_IDX_W-1:0]] <= vector_table[3];
                current_wr_ptr_state = current_wr_ptr_state + 1;
            end

            // Process bit 4
            if (new_irq_reg[4] && !full_reg) begin
                vector_fifo[current_wr_ptr_state[ADDR_IDX_W-1:0]] <= vector_table[4];
                current_wr_ptr_state = current_wr_ptr_state + 1;
            end

            // Process bit 5
            if (new_irq_reg[5] && !full_reg) begin
                vector_fifo[current_wr_ptr_state[ADDR_IDX_W-1:0]] <= vector_table[5];
                current_wr_ptr_state = current_wr_ptr_state + 1;
            end

            // Process bit 6
            if (new_irq_reg[6] && !full_reg) begin
                vector_fifo[current_wr_ptr_state[ADDR_IDX_W-1:0]] <= vector_table[6];
                current_wr_ptr_state = current_wr_ptr_state + 1;
            end

            // Process bit 7
            if (new_irq_reg[7] && !full_reg) begin
                vector_fifo[current_wr_ptr_state[ADDR_IDX_W-1:0]] <= vector_table[7];
                current_wr_ptr_state = current_wr_ptr_state + 1;
            end

            // Assign the calculated next write pointer value at the clock edge
            wr_ptr <= current_wr_ptr_state;
            
            // Read logic: Increment read pointer based on registered ack and empty
            if (ack_reg && !empty_reg) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    // Assign registered outputs
    assign curr_vector = curr_vector_reg;
    assign has_pending = has_pending_reg;

endmodule