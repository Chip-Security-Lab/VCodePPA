module asr_shift #(
    parameter DATA_W = 32
)(
    input clk_i, rst_i,
    input [DATA_W-1:0] data_i,
    input [$clog2(DATA_W)-1:0] shift_i,
    output reg [DATA_W-1:0] data_o
);
    // 使用标准Verilog替代SystemVerilog
    always @(posedge clk_i) begin
        if (rst_i)
            data_o <= {DATA_W{1'b0}};
        else begin
            // 实现有符号右移，不使用$signed和>>>
            data_o <= (data_i[DATA_W-1]) ? 
                     ((data_i >> shift_i) | (~({DATA_W{1'b0}} >> shift_i))) : 
                     (data_i >> shift_i);
        end
    end
endmodule