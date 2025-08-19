module serial_to_parallel #(
    parameter WIDTH = 8
)(
    input wire clk, rst_n, en,
    input wire serial_in,
    output reg [WIDTH-1:0] parallel_out,
    output reg done
);
    reg [$clog2(WIDTH):0] count;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            parallel_out <= 0;
            done <= 0;
        end else if (en) begin
            if (count == WIDTH) begin
                count <= 0;
                done <= 1;
            end else begin
                parallel_out <= {parallel_out[WIDTH-2:0], serial_in};
                count <= count + 1;
                done <= 0;
            end
        end
    end
endmodule