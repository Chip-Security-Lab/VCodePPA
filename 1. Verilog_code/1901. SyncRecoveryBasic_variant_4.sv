//SystemVerilog
module SyncRecoveryBasic #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [WIDTH-1:0] noisy_in,
    output reg [WIDTH-1:0] clean_out
);

    // 改进的时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean_out <= {WIDTH{1'b0}};
        end
        else begin
            clean_out <= en ? noisy_in : clean_out;
        end
    end

endmodule