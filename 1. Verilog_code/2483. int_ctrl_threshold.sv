module int_ctrl_threshold #(
    parameter WIDTH = 6,
    parameter THRESHOLD = 3
)(
    input clk, rst,
    input [WIDTH-1:0] req,
    output reg valid,
    output reg [2:0] code
);
    // Create a mask for values >= THRESHOLD
    wire [WIDTH-1:0] masked_req = req & ~((1 << THRESHOLD) - 1);
    integer i;
    
    always @(posedge clk) begin
        if(rst) begin
            valid <= 1'b0;
            code <= 3'b0;
        end else begin
            valid <= |masked_req;
            code <= 3'b0;
            for(i = 0; i < WIDTH; i = i + 1)
                if(masked_req[i]) code <= i[2:0];
        end
    end
endmodule