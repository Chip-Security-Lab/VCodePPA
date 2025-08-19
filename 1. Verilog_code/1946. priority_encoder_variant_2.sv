//SystemVerilog
module priority_encoder #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] request,
    output reg [$clog2(WIDTH)-1:0] grant_id,
    output reg valid
);
    integer k;
    reg [$clog2(WIDTH)-1:0] temp_id;
    reg temp_valid;

    always @(*) begin
        temp_id = {($clog2(WIDTH)){1'b0}};
        temp_valid = 1'b0;
        for (k = WIDTH-1; k >= 0; k = k - 1) begin
            if (request[k]) begin
                temp_id = k[$clog2(WIDTH)-1:0];
                temp_valid = 1'b1;
            end
        end
        grant_id = temp_id;
        valid = temp_valid;
    end
endmodule