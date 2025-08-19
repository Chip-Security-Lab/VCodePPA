//SystemVerilog
/////////////////////////////////////////////
// 顶层模块 - 控制整体流程和子模块连接
/////////////////////////////////////////////
module Comparator_FSM #(parameter WIDTH = 16) (
    input              clk,
    input              start,
    input  [WIDTH-1:0] val_m,
    input  [WIDTH-1:0] val_n,
    output             done,
    output             equal
);
    // 内部连接信号
    wire                       control_start_compare;
    wire                       control_reset_bit_cnt;
    wire                       control_done;
    wire                       compare_equal;
    wire                       compare_done;
    wire [$clog2(WIDTH)-1:0]   bit_cnt;
    wire                       increment_bit_cnt;
    
    // 状态控制器子模块
    FSM_Controller controller (
        .clk              (clk),
        .start            (start),
        .compare_done     (compare_done),
        .compare_equal    (compare_equal),
        .start_compare    (control_start_compare),
        .reset_bit_cnt    (control_reset_bit_cnt),
        .done             (done)
    );
    
    // 比特计数器子模块
    Bit_Counter #(
        .WIDTH            (WIDTH)
    ) counter (
        .clk              (clk),
        .reset            (control_reset_bit_cnt),
        .increment        (increment_bit_cnt),
        .bit_cnt          (bit_cnt)
    );
    
    // 比较器子模块
    Bit_Comparator #(
        .WIDTH            (WIDTH)
    ) comparator (
        .clk              (clk),
        .start            (control_start_compare),
        .val_m            (val_m),
        .val_n            (val_n),
        .bit_cnt          (bit_cnt),
        .max_bit          (WIDTH-1),
        .increment_bit    (increment_bit_cnt),
        .done             (compare_done),
        .equal            (compare_equal)
    );
    
    // 结果锁存器子模块
    Result_Latch result_latch (
        .clk              (clk),
        .compare_done     (compare_done),
        .compare_equal    (compare_equal),
        .equal_out        (equal)
    );
    
endmodule

/////////////////////////////////////////////
// 状态控制器子模块 - 管理FSM状态转换
/////////////////////////////////////////////
module FSM_Controller (
    input  wire clk,
    input  wire start,
    input  wire compare_done,
    input  wire compare_equal,
    output reg  start_compare,
    output reg  reset_bit_cnt,
    output reg  done
);
    // 状态定义
    localparam IDLE    = 2'b00;
    localparam COMPARE = 2'b01;
    localparam DONE    = 2'b10;
    
    reg [1:0] curr_state;
    
    // 初始化
    initial begin
        curr_state = IDLE;
        done = 0;
        start_compare = 0;
        reset_bit_cnt = 0;
    end
    
    always @(posedge clk) begin
        case(curr_state)
            IDLE: begin
                if (start) begin
                    reset_bit_cnt <= 1;
                    start_compare <= 1;
                    curr_state <= COMPARE;
                end else begin
                    reset_bit_cnt <= 0;
                    start_compare <= 0;
                end
                done <= 0;
            end
            
            COMPARE: begin
                reset_bit_cnt <= 0;
                start_compare <= 0;
                
                if (compare_done) begin
                    curr_state <= DONE;
                end
            end
            
            DONE: begin
                done <= 1;
                curr_state <= IDLE;
            end
            
            default: begin
                curr_state <= IDLE;
                done <= 0;
                start_compare <= 0;
                reset_bit_cnt <= 0;
            end
        endcase
    end
endmodule

/////////////////////////////////////////////
// 比特计数器子模块 - 追踪当前比较的位位置
/////////////////////////////////////////////
module Bit_Counter #(parameter WIDTH = 16) (
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     increment,
    output reg  [$clog2(WIDTH)-1:0] bit_cnt
);
    // 初始化
    initial begin
        bit_cnt = 0;
    end
    
    always @(posedge clk) begin
        if (reset) begin
            bit_cnt <= 0;
        end else if (increment) begin
            bit_cnt <= bit_cnt + 1;
        end
    end
endmodule

/////////////////////////////////////////////
// 比特比较器子模块 - 执行实际的比较功能
/////////////////////////////////////////////
module Bit_Comparator #(parameter WIDTH = 16) (
    input  wire                     clk,
    input  wire                     start,
    input  wire [WIDTH-1:0]         val_m,
    input  wire [WIDTH-1:0]         val_n,
    input  wire [$clog2(WIDTH)-1:0] bit_cnt,
    input  wire [$clog2(WIDTH)-1:0] max_bit,
    output reg                      increment_bit,
    output reg                      done,
    output reg                      equal
);
    // 比较状态
    localparam IDLE      = 1'b0;
    localparam COMPARING = 1'b1;
    
    reg state;
    
    // 初始化
    initial begin
        state = IDLE;
        done = 0;
        equal = 0;
        increment_bit = 0;
    end
    
    always @(posedge clk) begin
        case(state)
            IDLE: begin
                if (start) begin
                    state <= COMPARING;
                    equal <= 1; // 假设相等，直到发现不等
                    done <= 0;
                    increment_bit <= 0;
                end
            end
            
            COMPARING: begin
                if (val_m[bit_cnt] != val_n[bit_cnt]) begin
                    equal <= 0;
                    done <= 1;
                    state <= IDLE;
                    increment_bit <= 0;
                end else if (bit_cnt == max_bit) begin
                    done <= 1;
                    state <= IDLE;
                    increment_bit <= 0;
                end else begin
                    increment_bit <= 1;
                end
            end
        endcase
    end
endmodule

/////////////////////////////////////////////
// 结果锁存器子模块 - 锁存并输出最终结果
/////////////////////////////////////////////
module Result_Latch (
    input  wire clk,
    input  wire compare_done,
    input  wire compare_equal,
    output reg  equal_out
);
    // 初始化
    initial begin
        equal_out = 0;
    end
    
    always @(posedge clk) begin
        if (compare_done) begin
            equal_out <= compare_equal;
        end
    end
endmodule