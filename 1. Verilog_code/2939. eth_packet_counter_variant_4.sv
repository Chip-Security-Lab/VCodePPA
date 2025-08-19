//SystemVerilog
// Top-level module
module eth_packet_counter #(
    parameter COUNTER_WIDTH = 32
) (
    input  wire                       clk,
    input  wire                       reset_n,
    input  wire                       packet_valid,
    input  wire                       packet_error,
    output reg  [COUNTER_WIDTH-1:0]   good_packets,
    output reg  [COUNTER_WIDTH-1:0]   error_packets,
    output reg  [COUNTER_WIDTH-1:0]   total_packets
);
    // Control signals
    wire good_increment;
    wire error_increment;
    
    // Next counter values
    wire [COUNTER_WIDTH-1:0] total_next;
    wire [COUNTER_WIDTH-1:0] good_next;
    wire [COUNTER_WIDTH-1:0] error_next;
    
    // Control logic module
    packet_controller u_controller (
        .packet_valid   (packet_valid),
        .packet_error   (packet_error),
        .good_increment (good_increment),
        .error_increment(error_increment)
    );
    
    // Counter modules
    manchester_counter #(
        .WIDTH(COUNTER_WIDTH)
    ) u_total_counter (
        .current_value (total_packets),
        .increment     (packet_valid),
        .next_value    (total_next)
    );
    
    manchester_counter #(
        .WIDTH(COUNTER_WIDTH)
    ) u_good_counter (
        .current_value (good_packets),
        .increment     (good_increment),
        .next_value    (good_next)
    );
    
    manchester_counter #(
        .WIDTH(COUNTER_WIDTH)
    ) u_error_counter (
        .current_value (error_packets),
        .increment     (error_increment),
        .next_value    (error_next)
    );
    
    // Register update logic
    counter_registers #(
        .WIDTH(COUNTER_WIDTH)
    ) u_registers (
        .clk           (clk),
        .reset_n       (reset_n),
        .packet_valid  (packet_valid),
        .good_increment(good_increment),
        .error_increment(error_increment),
        .total_next    (total_next),
        .good_next     (good_next),
        .error_next    (error_next),
        .total_packets (total_packets),
        .good_packets  (good_packets),
        .error_packets (error_packets)
    );
    
endmodule

// Packet controller module
module packet_controller (
    input  wire packet_valid,
    input  wire packet_error,
    output wire good_increment,
    output wire error_increment
);
    // Determine which counter to increment
    assign good_increment  = packet_valid & ~packet_error;
    assign error_increment = packet_valid &  packet_error;
endmodule

// Manchester carry chain counter
module manchester_counter #(
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] current_value,
    input  wire             increment,
    output wire [WIDTH-1:0] next_value
);
    // Generate and propagate signals
    wire [WIDTH-1:0] g_signals;
    wire [WIDTH-1:0] p_signals;
    wire [WIDTH:0]   carry_chain;
    
    // Input carry to initiate increment
    assign carry_chain[0] = increment;
    
    // Manchester carry chain implementation
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : adder
            // Generate and propagate calculation - optimized to reduce logic
            assign g_signals[i] = 1'b0; // Generate is always 0 when adding 1
            assign p_signals[i] = current_value[i]; // Propagate equals current value
            
            // Carry chain
            assign carry_chain[i+1] = g_signals[i] | (p_signals[i] & carry_chain[i]);
            
            // Sum calculation
            assign next_value[i] = current_value[i] ^ carry_chain[i];
        end
    endgenerate
endmodule

// Counter registers module
module counter_registers #(
    parameter WIDTH = 32
) (
    input  wire             clk,
    input  wire             reset_n,
    input  wire             packet_valid,
    input  wire             good_increment,
    input  wire             error_increment,
    input  wire [WIDTH-1:0] total_next,
    input  wire [WIDTH-1:0] good_next,
    input  wire [WIDTH-1:0] error_next,
    output reg  [WIDTH-1:0] total_packets,
    output reg  [WIDTH-1:0] good_packets,
    output reg  [WIDTH-1:0] error_packets
);
    // Sequential logic for counter registers
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Reset all counters
            good_packets  <= {WIDTH{1'b0}};
            error_packets <= {WIDTH{1'b0}};
            total_packets <= {WIDTH{1'b0}};
        end else begin
            // Update counters based on control signals
            if (packet_valid) begin
                total_packets <= total_next;
                
                if (good_increment)
                    good_packets <= good_next;
                    
                if (error_increment)
                    error_packets <= error_next;
            end
        end
    end
endmodule