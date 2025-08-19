module priority_encoder #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] request,
    output reg [$clog2(WIDTH)-1:0] grant_id,
    output reg valid
);
    integer i;
    
    always @(*) begin
        valid = 1'b0;
        grant_id = 0;
        
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (request[i] && !valid) begin
                grant_id = i;
                valid = 1'b1;
            end
        end
    end
endmodule