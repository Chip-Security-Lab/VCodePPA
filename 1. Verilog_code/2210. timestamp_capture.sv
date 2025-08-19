module timestamp_capture #(
    parameter TIMESTAMP_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire [3:0] event_triggers,
    output reg [3:0] event_detected,
    output reg [TIMESTAMP_WIDTH-1:0] timestamps [0:3]
);
    reg [TIMESTAMP_WIDTH-1:0] free_running_counter;
    reg [3:0] last_triggers;
    
    always @(posedge clk) begin
        if (rst) begin
            free_running_counter <= {TIMESTAMP_WIDTH{1'b0}};
            event_detected <= 4'b0000;
            last_triggers <= 4'b0000;
        end else begin
            free_running_counter <= free_running_counter + 1'b1;
            last_triggers <= event_triggers;
            
            // Edge detection and timestamp capture
            begin : capture_block
                integer i;
                for (i = 0; i < 4; i = i + 1) begin
                    if (event_triggers[i] && !last_triggers[i]) begin
                        timestamps[i] <= free_running_counter;
                        event_detected[i] <= 1'b1;
                    end
                end
            end
        end
    end
endmodule