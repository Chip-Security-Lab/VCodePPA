module error_detect_bridge #(parameter DWIDTH=32) (
    input clk, rst_n,
    input [DWIDTH-1:0] in_data,
    input in_valid,
    output reg in_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    output reg error,
    input out_ready
);
    // 奇偶校验计算
    reg calc_parity;
    integer j;
    
    always @(*) begin
        calc_parity = 0;
        for (j = 0; j < DWIDTH; j = j + 1)
            calc_parity = calc_parity ^ in_data[j];
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 0;
            in_ready <= 1;
            error <= 0;
            out_data <= 0;
        end else if (in_valid && in_ready) begin
            out_data <= in_data;
            out_valid <= 1;
            in_ready <= 0;
            error <= calc_parity ? 1'b0 : 1'b1;  // 奇校验
        end else if (out_valid && out_ready) begin
            out_valid <= 0;
            in_ready <= 1;
            error <= 0;
        end
    end
endmodule