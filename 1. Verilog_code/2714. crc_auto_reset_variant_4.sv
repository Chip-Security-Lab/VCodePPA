//SystemVerilog
// 顶层模块
module crc_auto_reset #(
    parameter MAX_COUNT = 255
)(
    input wire clk,
    input wire start,
    input wire [7:0] data_stream,
    output wire [15:0] crc,
    output wire done
);
    // 内部连线
    wire [15:0] crc_next_value;
    wire counter_reset;
    wire [8:0] counter_value;
    
    // CRC计算子模块
    crc_calculator u_crc_calculator (
        .crc_in(crc),
        .data(data_stream),
        .crc_out(crc_next_value)
    );
    
    // 计数器子模块
    counter_module #(
        .MAX_COUNT(MAX_COUNT)
    ) u_counter (
        .clk(clk),
        .reset(counter_reset),
        .enable(~done),
        .counter(counter_value),
        .done(done)
    );
    
    // CRC寄存器子模块
    crc_register u_crc_register (
        .clk(clk),
        .start(start),
        .crc_next(crc_next_value),
        .counter_value(counter_value),
        .max_count(MAX_COUNT),
        .crc(crc),
        .counter_reset(counter_reset)
    );
endmodule

// CRC计算子模块
module crc_calculator (
    input wire [15:0] crc_in,
    input wire [7:0] data,
    output wire [15:0] crc_out
);
    // 优化的CRC计算逻辑
    assign crc_out = {crc_in[14:0], 1'b0} ^ 
                    (crc_in[15] ? 16'h8005 : 16'h0000) ^ 
                    {8'h00, data};
endmodule

// 计数器子模块
module counter_module #(
    parameter MAX_COUNT = 255
)(
    input wire clk,
    input wire reset,
    input wire enable,
    output reg [8:0] counter,
    output wire done
);
    always @(posedge clk) begin
        if (reset) begin
            counter <= 9'b0;
        end else if (enable) begin
            counter <= counter + 9'b1;
        end
    end
    
    assign done = (counter == MAX_COUNT);
endmodule

// CRC寄存器子模块
module crc_register (
    input wire clk,
    input wire start,
    input wire [15:0] crc_next,
    input wire [8:0] counter_value,
    input wire [8:0] max_count,
    output reg [15:0] crc,
    output wire counter_reset
);
    assign counter_reset = start;
    
    always @(posedge clk) begin
        if (start) begin
            crc <= 16'hFFFF;
        end else if (counter_value < max_count) begin
            crc <= crc_next;
        end
    end
endmodule