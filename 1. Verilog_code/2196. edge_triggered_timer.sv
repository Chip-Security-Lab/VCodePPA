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
    
    assign trigger_edge = trigger & ~trigger_prev;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= {WIDTH{1'b0}};
            timer_active <= 1'b0;
            timeout <= 1'b0;
            trigger_prev <= 1'b0;
        end else begin
            trigger_prev <= trigger;
            
            if (trigger_edge) begin
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