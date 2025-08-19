//SystemVerilog
module int_ctrl_adapt #(
    parameter N = 4
)(
    input clk, rst,
    input [N-1:0] req,
    input [N-1:0] service_time,
    output reg [N-1:0] grant
);
    reg [7:0] hist_counter[0:N-1];
    reg [7:0] min_counter;
    reg [N-1:0] min_index;
    integer i;
    
    always @(posedge clk) begin
        if(rst) begin
            i = 0;
            while(i < N) begin
                hist_counter[i] <= 8'hFF;
                i = i + 1;
            end
            grant <= 0;
        end else begin
            // Pre-calculate the adaptation logic in parallel
            i = 0;
            while(i < N) begin
                if (req[i] && service_time[i] && (hist_counter[i] > service_time[i])) begin
                    hist_counter[i] <= service_time[i];
                end
                i = i + 1;
            end
            
            // Find minimum in a balanced tree structure
            min_counter = 8'hFF;
            min_index = 0;
            
            i = 0;
            while(i < N) begin
                if (req[i] && (hist_counter[i] < min_counter)) begin
                    min_counter = hist_counter[i];
                    min_index = i;
                end
                i = i + 1;
            end
            
            // Generate grant signal
            grant <= 0;
            if (|req) begin // Only process if at least one request
                grant[min_index] <= 1'b1;
            end
        end
    end
endmodule