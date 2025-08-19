//SystemVerilog
module priority_encoder #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] request,
    output reg [$clog2(WIDTH)-1:0] grant_id,
    output reg valid
);
    integer idx;
    reg [$clog2(WIDTH)-1:0] internal_grant_id;
    reg internal_valid;

    always @(*) begin
        internal_valid = |request;
        internal_grant_id = 0;
        idx = WIDTH - 1;
        while (idx >= 0) begin
            if (request[idx]) begin
                internal_grant_id = idx[$clog2(WIDTH)-1:0];
            end
            idx = idx - 1;
        end
        grant_id = internal_grant_id;
        valid = internal_valid;
    end
endmodule