module biphase_mark_enc (
    input clk, rst_n,
    input data_in,
    output reg encoded
);
    reg phase;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) {encoded, phase} <= 0;
        else begin
            phase <= ~phase;
            encoded <= data_in ? phase : ~phase;
        end
    end
endmodule