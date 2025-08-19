//SystemVerilog
///////////////////////////////////////////////////////////
// File: enabled_ring_counter_top.v
// Top-level module for ring counter with enable control
///////////////////////////////////////////////////////////

module enabled_ring_counter(
    input wire clock,
    input wire reset,
    input wire enable,
    output wire [3:0] count
);
    // Internal signals
    wire reset_sync;
    wire enable_after_reset;
    wire [3:0] next_count;
    wire [3:0] current_count;
    
    // Reset synchronization submodule
    reset_synchronizer u_reset_sync (
        .clock(clock),
        .reset_in(reset),
        .reset_out(reset_sync)
    );
    
    // Enable control submodule - with forward retiming
    enable_controller u_enable_ctrl (
        .clock(clock),
        .reset_sync(reset_sync),
        .enable_in(enable),
        .enable_out(enable_after_reset)
    );
    
    // Next state generation submodule
    next_state_generator u_next_state (
        .current_count(current_count),
        .next_count(next_count)
    );
    
    // Counter register submodule
    counter_register u_counter_reg (
        .clock(clock),
        .reset_sync(reset_sync),
        .enable_sync(enable_after_reset),
        .next_count(next_count),
        .current_count(current_count)
    );
    
    // Output assignment
    assign count = current_count;
    
endmodule

///////////////////////////////////////////////////////////
// Reset synchronizer module
// Synchronizes the asynchronous reset signal
///////////////////////////////////////////////////////////

module reset_synchronizer(
    input wire clock,
    input wire reset_in,
    output wire reset_out
);
    // Metastability protection registers
    reg reset_meta;
    reg reset_out_reg;
    
    // Forward retimed reset synchronization
    always @(posedge clock or posedge reset_in) begin
        if (reset_in) begin
            reset_meta <= 1'b1;
        end else begin
            reset_meta <= 1'b0;
        end
    end
    
    always @(posedge clock or posedge reset_in) begin
        if (reset_in) begin
            reset_out_reg <= 1'b1;
        end else begin
            reset_out_reg <= reset_meta;
        end
    end
    
    assign reset_out = reset_out_reg;
endmodule

///////////////////////////////////////////////////////////
// Enable controller module
// Handles the enable signal and its synchronization
///////////////////////////////////////////////////////////

module enable_controller(
    input wire clock,
    input wire reset_sync,
    input wire enable_in,
    output wire enable_out
);
    // Capture input enable signal without reset first
    reg enable_captured;
    reg enable_out_reg;
    
    // Forward retiming - move register past combinational logic
    always @(posedge clock) begin
        enable_captured <= enable_in;
    end
    
    always @(posedge clock) begin
        if (reset_sync)
            enable_out_reg <= 1'b0;
        else
            enable_out_reg <= enable_captured;
    end
    
    assign enable_out = enable_out_reg;
endmodule

///////////////////////////////////////////////////////////
// Next state generator module
// Calculates the next state of the ring counter
///////////////////////////////////////////////////////////

module next_state_generator(
    input wire [3:0] current_count,
    output wire [3:0] next_count
);
    assign next_count = {current_count[2:0], current_count[3]};
endmodule

///////////////////////////////////////////////////////////
// Counter register module
// Stores the current count value
///////////////////////////////////////////////////////////

module counter_register(
    input wire clock,
    input wire reset_sync,
    input wire enable_sync,
    input wire [3:0] next_count,
    output wire [3:0] current_count
);
    reg [3:0] count_reg;
    
    always @(posedge clock) begin
        if (reset_sync)
            count_reg <= 4'b0001;
        else if (enable_sync)
            count_reg <= next_count;
    end
    
    assign current_count = count_reg;
endmodule