//SystemVerilog
module edge_triggered_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire reset_n,
    input wire trigger,
    input wire [WIDTH-1:0] duration,
    output reg timer_active,
    output reg timeout
);
    reg [WIDTH-1:0] counter;
    reg trigger_prev;
    wire trigger_edge;
    
    // Buffered trigger_edge signal to reduce fan-out
    wire trigger_edge_unbuf;
    reg trigger_edge_buf1, trigger_edge_buf2;
    
    assign trigger_edge_unbuf = trigger & ~trigger_prev;
    
    // Registered buffers for high fan-out trigger_edge signal
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            trigger_edge_buf1 <= 1'b0;
            trigger_edge_buf2 <= 1'b0;
        end else begin
            trigger_edge_buf1 <= trigger_edge_unbuf;
            trigger_edge_buf2 <= trigger_edge_unbuf;
        end
    end
    
    // Use buffered signals based on load requirements
    assign trigger_edge = trigger_edge_unbuf;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= {WIDTH{1'b0}};
            timer_active <= 1'b0;
            timeout <= 1'b0;
            trigger_prev <= 1'b0;
        end else begin
            trigger_prev <= trigger;
            
            if (trigger_edge_buf1) begin
                counter <= {WIDTH{1'b0}};
                timer_active <= 1'b1;
                timeout <= 1'b0;
            end else if (timer_active) begin
                if (counter >= duration - 1) begin
                    timer_active <= 1'b0;
                    timeout <= 1'b1;
                end else begin
                    counter <= counter + 1'b1;
                end
            end
        end
    end
endmodule