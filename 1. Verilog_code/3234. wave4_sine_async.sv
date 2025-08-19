module wave4_sine_async #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8
)(
    input  wire [ADDR_WIDTH-1:0] addr,
    output wire [DATA_WIDTH-1:0] wave_out
);
    (* ram_style = "distributed" *) reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];
    reg [DATA_WIDTH-1:0] data_reg;

    // 初始化ROM
    initial begin
        integer i;
        for(i=0; i<(1<<ADDR_WIDTH); i=i+1) begin
            rom[i] = i % (1<<DATA_WIDTH);
        end
    end

    // 使用寄存器来保存输出以避免综合问题
    always @(addr) begin
        data_reg = rom[addr];
    end
    
    assign wave_out = data_reg;
endmodule