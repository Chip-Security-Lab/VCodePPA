module interval_timer (
    input wire clk,
    input wire rst,
    input wire program_en,
    input wire [7:0] interval_data,
    input wire [3:0] interval_sel,
    output reg event_trigger
);
    reg [7:0] intervals [0:15];
    reg [7:0] current_count;
    reg [3:0] active_interval;
    
    always @(posedge clk) begin
        if (rst) begin
            current_count <= 8'd0;
            event_trigger <= 1'b0;
            active_interval <= 4'd0;
        end else if (program_en) begin
            intervals[interval_sel] <= interval_data;
        end else begin
            if (current_count >= intervals[active_interval]) begin
                current_count <= 8'd0;
                event_trigger <= 1'b1;
                active_interval <= active_interval + 1'b1;
            end else begin
                current_count <= current_count + 1'b1;
                event_trigger <= 1'b0;
            end
        end
    end
endmodule
