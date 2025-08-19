//SystemVerilog
module loadable_ring_counter(
    input  wire       clock,
    input  wire       reset,
    input  wire       load,
    input  wire [3:0] data_in,
    output reg  [3:0] ring_out
);
    // Pipeline stage 1: Control signal generation and input preparation
    reg        reset_r, load_r;
    reg  [3:0] data_in_r;
    
    // Pipeline stage 2: State calculation
    reg  [3:0] next_state;
    
    // Stage 1: Register control inputs and data inputs
    always @(posedge clock) begin
        reset_r   <= reset;
        load_r    <= load;
        data_in_r <= data_in;
    end
    
    // Stage 2: Calculate next state based on registered controls
    always @(posedge clock) begin
        if (reset_r)
            next_state <= 4'b0001;  // Reset state
        else if (load_r)
            next_state <= data_in_r; // Load external data
        else
            next_state <= {ring_out[2:0], ring_out[3]}; // Ring shift operation
    end
    
    // Final output stage: Update ring counter output
    always @(posedge clock) begin
        ring_out <= next_state;
    end
endmodule