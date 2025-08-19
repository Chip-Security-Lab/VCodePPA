//SystemVerilog
//IEEE 1364-2005
module oneshot_timer (
    input wire clock,
    input wire reset,
    input wire trigger,
    input wire [15:0] duration,
    output reg pulse_out
);
    reg [15:0] count;
    reg active;
    reg prev_trigger;
    
    // Pipeline registers
    reg trigger_edge_p1;
    reg pulse_complete_p1;
    reg [15:0] duration_reg;
    
    // Optimized edge detection
    wire trigger_edge = trigger && !prev_trigger;
    
    // Optimized comparison logic - using "less than" instead of equality check
    // This is more efficient in hardware implementation
    wire pulse_complete = active && (count >= duration_reg);
    
    always @(posedge clock) begin
        if (reset) begin
            count <= 16'd0;
            active <= 1'b0;
            pulse_out <= 1'b0;
            prev_trigger <= 1'b0;
            trigger_edge_p1 <= 1'b0;
            pulse_complete_p1 <= 1'b0;
            duration_reg <= 16'd0;
        end else begin
            // Pipeline stage 1: Register inputs and preliminary calculations
            prev_trigger <= trigger;
            trigger_edge_p1 <= trigger_edge;
            pulse_complete_p1 <= pulse_complete;
            duration_reg <= duration;
            
            // Pipeline stage 2: Process control logic based on pipelined signals
            if (trigger_edge_p1) begin
                active <= 1'b1;
                count <= 16'd0;
                pulse_out <= 1'b1;
            end else if (pulse_complete_p1) begin
                active <= 1'b0;
                pulse_out <= 1'b0;
            end else if (active) begin
                count <= count + 16'd1;
            end
        end
    end
endmodule