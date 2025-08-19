//SystemVerilog
// 顶层模块
module power_optimized_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire valid,
    input wire power_save,
    output reg [7:0] crc,
    output wire ready
);
    parameter [7:0] POLY = 8'h07;
    
    // 时钟门控模块实例化
    wire gated_clk;
    clock_gate u_clock_gate(
        .clk(clk),
        .power_save(power_save),
        .gated_clk(gated_clk)
    );
    
    // CRC计算模块实例化
    crc_calculator u_crc_calc(
        .clk(gated_clk),
        .rst(rst),
        .data(data),
        .valid(valid),
        .poly(POLY),
        .crc(crc)
    );
    
    // Ready信号生成模块实例化
    ready_generator u_ready_gen(
        .ready(ready)
    );

endmodule

// 时钟门控子模块
module clock_gate(
    input wire clk,
    input wire power_save,
    output wire gated_clk
);
    assign gated_clk = clk & ~power_save;
endmodule

// CRC计算子模块
module crc_calculator(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire valid,
    input wire [7:0] poly,
    output reg [7:0] crc
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc <= 8'h00;
        end
        else if (valid) begin
            crc <= {crc[6:0], 1'b0} ^ ((crc[7] ^ data[0]) ? poly : 8'h00);
        end
    end
endmodule

// Ready信号生成子模块
module ready_generator(
    output wire ready
);
    assign ready = 1'b1;
endmodule