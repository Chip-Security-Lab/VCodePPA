module wave13_half_rect_sine #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    output reg  [DATA_WIDTH-1:0] wave_out
);
    reg [ADDR_WIDTH-1:0] addr;
    reg signed [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];

    // 使用$signed确保正确处理有符号数
    initial begin
        integer i;
        for(i=0; i<(1<<ADDR_WIDTH); i=i+1) 
            rom[i] = $signed(i - (1<<(DATA_WIDTH-1)));
    end

    always @(posedge clk) begin
        if(rst) addr <= 0;
        else    addr <= addr + 1;
        // 使用$signed确保正确比较
        wave_out <= ($signed(rom[addr]) < 0) ? 0 : rom[addr][DATA_WIDTH-1:0];
    end
endmodule