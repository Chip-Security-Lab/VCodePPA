module sram_mbist #(
    parameter AW = 5,
    parameter DW = 8
)(
    input clk,
    input test_mode,
    output error_flag
);
reg [DW-1:0] mem [0:(1<<AW)-1];
reg [AW:0] test_counter;
reg test_stage;
wire [DW-1:0] expected = test_stage ? {DW{1'b1}} : {DW{1'b0}};

always @(posedge clk) begin
    if (test_mode) begin
        test_counter <= test_counter + 1;
        if (test_counter[AW]) test_stage <= ~test_stage;
        mem[test_counter[AW-1:0]] <= expected;
    end
end

assign error_flag = test_mode ? 
    (mem[test_counter[AW-1:0]] !== expected) : 1'b0;
endmodule
