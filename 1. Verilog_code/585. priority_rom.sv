module priority_rom (
    input clk,
    input [3:0] addr_high,
    input [3:0] addr_low,
    input high_priority,  // 高优先级信号
    output reg [7:0] data
);
    reg [7:0] rom [0:15];

    initial begin
        rom[0] = 8'h55; rom[1] = 8'h66;
    end

    always @(posedge clk) begin
        if (high_priority)
            data <= rom[addr_high]; // 高优先级端口先访问
        else
            data <= rom[addr_low];
    end
endmodule
