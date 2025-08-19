//SystemVerilog
module sync_pulse_generator(
    input clk_i,
    input rst_i,
    input en_i,
    input [15:0] period_i,
    input [15:0] width_i,
    output reg pulse_o,
    output reg req_o,
    input ack_i
);
    reg [15:0] counter;
    reg period_reached;
    reg width_reached;
    reg req_pending;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            counter <= 16'd0;
            pulse_o <= 1'b0;
            req_o <= 1'b0;
            req_pending <= 1'b0;
        end else if (en_i) begin
            // Pre-compute comparison results to reduce critical path
            period_reached = (counter >= period_i-1);
            width_reached = (counter >= width_i);
            
            // Update counter based on pre-computed condition
            counter <= period_reached ? 16'd0 : counter + 16'd1;
            
            // Use pre-computed width comparison for pulse generation
            pulse_o <= width_reached ? 1'b0 : 1'b1;
            
            // Request-acknowledge handshake logic
            if (period_reached && !req_pending) begin
                req_o <= 1'b1;
                req_pending <= 1'b1;
            end else if (ack_i && req_pending) begin
                req_o <= 1'b0;
                req_pending <= 1'b0;
            end
        end
    end
endmodule