module Comparator_FSM #(parameter WIDTH = 16) (
    input              clk,
    input              start,
    input  [WIDTH-1:0] val_m,
    input  [WIDTH-1:0] val_n,
    output reg         done,
    output reg         equal
);
    // 使用localparam替代SystemVerilog的typedef enum
    localparam IDLE = 2'b00;
    localparam COMPARE = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] curr_state;
    reg [$clog2(WIDTH)-1:0] bit_cnt;

    // 初始化FSM状态
    initial begin
        curr_state = IDLE;
        done = 0;
        equal = 0;
        bit_cnt = 0;
    end

    always @(posedge clk) begin
        case(curr_state)
            IDLE: begin
                if (start) begin
                    bit_cnt <= 0;
                    curr_state <= COMPARE;
                end
                done <= 0;
            end
            
            COMPARE: begin
                if (val_m[bit_cnt] != val_n[bit_cnt]) begin
                    equal <= 0;
                    curr_state <= DONE;
                end else if (bit_cnt == WIDTH-1) begin
                    equal <= 1;
                    curr_state <= DONE;
                end else begin
                    bit_cnt <= bit_cnt + 1;
                end
            end
            
            DONE: begin
                done <= 1;
                curr_state <= IDLE;
            end
            
            default: begin
                curr_state <= IDLE;
            end
        endcase
    end
endmodule