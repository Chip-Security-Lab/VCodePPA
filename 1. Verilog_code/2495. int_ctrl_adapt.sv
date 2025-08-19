module int_ctrl_adapt #(
    parameter N = 4
)(
    input clk, rst,
    input [N-1:0] req,
    input [N-1:0] service_time,
    output reg [N-1:0] grant
);
    reg [7:0] hist_counter[0:N-1];
    integer i;
    
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < N; i = i + 1)
                hist_counter[i] <= 8'hFF;
            grant <= 0;
        end else begin
            // Adaptation algorithm
            grant <= 0;
            for(i = 0; i < N; i = i + 1) begin
                if (req[i]) begin
                    // Simple adaptation: prioritize shorter service times
                    if (service_time[i] && (hist_counter[i] > service_time[i])) begin
                        hist_counter[i] <= service_time[i];
                    end
                    
                    // Grant to request with lowest historical service time
                    if (hist_counter[i] == 8'h01 || (i == 0)) begin
                        grant[i] <= 1'b1;
                    end
                end
            end
        end
    end
endmodule