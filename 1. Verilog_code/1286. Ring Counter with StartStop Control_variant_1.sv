//SystemVerilog
module controlled_ring_counter (
    input  wire       clock,
    input  wire       reset,
    input  wire       run,      // Start/stop control
    output reg  [3:0] state
);
    // Control path signals
    reg        run_reg;         // Registered run signal
    reg        running_status;  // Current running status
    wire       next_running;    // Next running status

    // Data path signals
    wire [3:0] next_state;      // Next state calculation
    reg  [3:0] state_reg;       // Internal state register
    
    // ===== Control Path Logic =====
    // Determine next running status with improved logic structure
    assign next_running = reset ? 1'b0 : 
                          run    ? 1'b1 : 
                          running_status;
    
    // ===== Data Path Logic =====
    // Calculate next state value with clear conditional structure
    assign next_state = reset ? 4'b0001 :
                       (running_status ? {state_reg[2:0], state_reg[3]} : state_reg);
    
    // ===== Sequential Logic =====
    always @(posedge clock) begin
        // Control path registers
        running_status <= next_running;
        run_reg <= run;
        
        // Data path registers
        state_reg <= next_state;
        state <= state_reg;     // Output register stage for improved timing
    end
endmodule