//SystemVerilog
// 顶层模块
module priority_buffer (
    input  wire       clk,
    input  wire [7:0] data_a, data_b, data_c,
    input  wire       valid_a, valid_b, valid_c,
    output reg  [7:0] data_out,
    output reg  [1:0] source
);
    // 内部信号
    wire [2:0] valid_signals;
    wire [7:0] selected_data;
    wire [1:0] selected_source;
    
    // 将有效信号组合到一个总线
    signal_collector valid_collector (
        .valid_a(valid_a),
        .valid_b(valid_b),
        .valid_c(valid_c),
        .valid_bus(valid_signals)
    );
    
    // 优先级选择逻辑
    priority_selector selector (
        .valid_bus(valid_signals),
        .data_a(data_a),
        .data_b(data_b),
        .data_c(data_c),
        .current_data(data_out),
        .current_source(source),
        .next_data(selected_data),
        .next_source(selected_source)
    );
    
    // 输出寄存器模块
    output_register out_reg (
        .clk(clk),
        .next_data(selected_data),
        .next_source(selected_source),
        .data_out(data_out),
        .source(source)
    );
endmodule

// 有效信号收集模块
module signal_collector (
    input  wire       valid_a, valid_b, valid_c,
    output wire [2:0] valid_bus
);
    assign valid_bus = {valid_c, valid_b, valid_a};
endmodule

// 优先级选择器模块
module priority_selector (
    input  wire [2:0] valid_bus,
    input  wire [7:0] data_a, data_b, data_c,
    input  wire [7:0] current_data,
    input  wire [1:0] current_source,
    output reg  [7:0] next_data,
    output reg  [1:0] next_source
);
    // 优先级选择逻辑，根据有效信号进行选择
    always @(*) begin
        casez (valid_bus)
            3'b??1: begin // valid_a 有效
                next_data = data_a;
                next_source = 2'b00;
            end
            3'b?10: begin // valid_a 无效，valid_b 有效
                next_data = data_b;
                next_source = 2'b01;
            end
            3'b100: begin // valid_a 和 valid_b 无效，valid_c 有效
                next_data = data_c;
                next_source = 2'b10;
            end
            default: begin // 保持当前值
                next_data = current_data;
                next_source = current_source;
            end
        endcase
    end
endmodule

// 输出寄存器模块
module output_register (
    input  wire       clk,
    input  wire [7:0] next_data,
    input  wire [1:0] next_source,
    output reg  [7:0] data_out,
    output reg  [1:0] source
);
    // 时序逻辑，将选择的数据和源更新到输出寄存器
    always @(posedge clk) begin
        data_out <= next_data;
        source <= next_source;
    end
endmodule