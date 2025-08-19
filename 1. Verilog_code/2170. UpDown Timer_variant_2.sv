//SystemVerilog
//IEEE 1364-2005 Verilog
module updown_timer #(parameter WIDTH = 16) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire up_down,  // 1 = up, 0 = down
    input wire [WIDTH-1:0] load_val,
    input wire load_en,
    output wire [WIDTH-1:0] count,
    output wire overflow,
    output wire underflow
);
    // 内部控制信号
    wire count_up_en;
    wire count_down_en;
    
    // 计数器核心模块
    counter_core #(
        .WIDTH(WIDTH)
    ) counter_unit (
        .clk(clk),
        .rst_n(rst_n),
        .load_en(load_en),
        .load_val(load_val),
        .count_up_en(count_up_en),
        .count_down_en(count_down_en),
        .count(count)
    );
    
    // 控制逻辑模块
    control_logic #(
        .WIDTH(WIDTH)
    ) control_unit (
        .en(en),
        .up_down(up_down),
        .load_en(load_en),
        .count(count),
        .count_up_en(count_up_en),
        .count_down_en(count_down_en)
    );
    
    // 状态检测模块
    status_detector #(
        .WIDTH(WIDTH)
    ) detector_unit (
        .en(en),
        .up_down(up_down),
        .count(count),
        .overflow(overflow),
        .underflow(underflow)
    );
    
endmodule

// 计数器核心模块 - 负责计数器值的更新
module counter_core #(parameter WIDTH = 16) (
    input wire clk,
    input wire rst_n,
    input wire load_en,
    input wire [WIDTH-1:0] load_val,
    input wire count_up_en,
    input wire count_down_en,
    output reg [WIDTH-1:0] count
);
    always @(posedge clk) begin
        if (!rst_n) begin
            // 复位状态
            count <= {WIDTH{1'b0}};
        end
        else if (load_en) begin
            // 加载新值
            count <= load_val;
        end
        else if (count_up_en) begin
            // 递增计数
            count <= count + 1'b1;
        end
        else if (count_down_en) begin
            // 递减计数
            count <= count - 1'b1;
        end
    end
endmodule

// 控制逻辑模块 - 生成内部控制信号
module control_logic #(parameter WIDTH = 16) (
    input wire en,
    input wire up_down,
    input wire load_en,
    input wire [WIDTH-1:0] count,
    output wire count_up_en,
    output wire count_down_en
);
    // 生成计数使能信号
    assign count_up_en = en & up_down & !load_en;
    assign count_down_en = en & !up_down & !load_en;
endmodule

// 状态检测模块 - 检测溢出和下溢状态
module status_detector #(parameter WIDTH = 16) (
    input wire en,
    input wire up_down,
    input wire [WIDTH-1:0] count,
    output wire overflow,
    output wire underflow
);
    // 溢出检测 - 当所有位都为1时，再次递增将产生溢出
    assign overflow = en & up_down & (&count);
    
    // 下溢检测 - 当所有位都为0时，再次递减将产生下溢
    assign underflow = en & ~up_down & (~|count);
endmodule