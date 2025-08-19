//SystemVerilog
module loadable_counter (
    input wire clk, rst, load, en,
    input wire [3:0] data,
    output reg [3:0] count
);
    // Control signals
    wire [2:0] ctrl;
    wire [3:0] next_count;
    
    // Moved control signal combination outside the register
    assign ctrl = {rst, load, en};
    
    // Carry look-ahead adder implementation
    wire [3:0] a, b;
    wire [4:0] carry;
    wire [3:0] p, g;
    
    // Input selection based on control signals
    assign a = count;
    assign b = (ctrl == 3'b001) ? 4'b0001 : 4'b0000;
    
    // Generate and propagate signals
    assign p = a ^ b;
    assign g = a & b;
    
    // Carry calculation using look-ahead logic
    assign carry[0] = 1'b0;
    assign carry[1] = g[0] | (p[0] & carry[0]);
    assign carry[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & carry[0]);
    assign carry[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & carry[0]);
    assign carry[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & carry[0]);
    
    // Sum calculation
    wire [3:0] sum;
    assign sum = p ^ {carry[3:0]};
    
    // Next count value selection based on control
    assign next_count = (ctrl[2]) ? 4'b0000 :           // rst == 1
                        (ctrl[1]) ? data :              // load == 1
                        (ctrl[0]) ? sum :               // en == 1 (increment using CLA)
                        count;                          // Hold current value
    
    // Register update at clock edge
    always @(posedge clk) begin
        count <= next_count;
    end
endmodule