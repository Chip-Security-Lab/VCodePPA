//SystemVerilog
module MuxBinaryEnc #(parameter W=8, N=16) (
    input [N-1:0] req,
    input [W-1:0] data [0:N-1],
    output reg [W-1:0] grant_data
);
    reg [W-1:0] temp_data;
    reg [N-1:0] req_mask;
    integer i;
    
    always @(*) begin
        temp_data = 0;
        req_mask = req;
        for (i = 0; i < N; i = i + 1) begin
            if (req_mask[i]) begin
                temp_data = data[i];
                req_mask = req_mask & ~(1 << i);
            end
        end
        grant_data = temp_data;
    end
endmodule