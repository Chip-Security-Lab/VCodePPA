module RangeDetector_FaultTolerant #(
    parameter WIDTH = 8,
    parameter TOLERANCE = 3
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] low_th,
    input [WIDTH-1:0] high_th,
    output reg alarm
);
reg [1:0] err_count;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        err_count <= 0;
        alarm <= 0;
    end
    else begin
        if(data_in < low_th || data_in > high_th) begin
            err_count <= (err_count < TOLERANCE) ? err_count + 1 : TOLERANCE;
        end
        else begin
            err_count <= (err_count > 0) ? err_count - 1 : 0;
        end
        
        alarm <= (err_count == TOLERANCE);
    end
end
endmodule