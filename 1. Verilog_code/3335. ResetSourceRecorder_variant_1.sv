//SystemVerilog
module ResetSourceRecorder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  reset_source,
    output reg  [1:0]  last_reset_source
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if (reset_source <= 2'b11) begin
                last_reset_source <= reset_source;
            end else begin
                last_reset_source <= 2'b00;
            end
        end
    end
endmodule