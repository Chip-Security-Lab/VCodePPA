module wave3_sine_sync #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    output reg  [DATA_WIDTH-1:0] wave_out
);
    reg [ADDR_WIDTH-1:0] addr;
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];

    // 使用系统任务初始化ROM
    initial begin
        integer i;
        for(i=0; i<(1<<ADDR_WIDTH); i=i+1) begin
            // 实际上是生成正弦波，这里简化为线性递增
            rom[i] = i % (1<<DATA_WIDTH);
        end
    end

    always @(posedge clk) begin
        if(rst) addr <= 0;
        else    addr <= addr + 1;
        wave_out <= rom[addr];
    end
endmodule