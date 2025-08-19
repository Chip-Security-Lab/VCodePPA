//SystemVerilog
module Comparator_FSM #(parameter WIDTH = 16) (
    input              clk,
    input              start,
    input  [WIDTH-1:0] val_m,
    input  [WIDTH-1:0] val_n,
    output reg         done,
    output reg         equal
);

    localparam IDLE = 2'b00;
    localparam COMPARE = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] curr_state, next_state;
    reg [$clog2(WIDTH)-1:0] bit_cnt, next_bit_cnt;
    reg next_done, next_equal;
    reg comp_result;

    initial begin
        curr_state = IDLE;
        done = 0;
        equal = 0;
        bit_cnt = 0;
    end

    always @(*) begin
        next_state = curr_state;
        next_bit_cnt = bit_cnt;
        next_done = done;
        next_equal = equal;
        comp_result = (val_m[bit_cnt] == val_n[bit_cnt]);
        
        if (curr_state == IDLE && start) begin
            next_bit_cnt = 0;
            next_state = COMPARE;
            next_done = 0;
        end
        else if (curr_state == COMPARE && !comp_result) begin
            next_equal = 0;
            next_state = DONE;
        end
        else if (curr_state == COMPARE && comp_result && bit_cnt == WIDTH-1) begin
            next_equal = 1;
            next_state = DONE;
        end
        else if (curr_state == COMPARE && comp_result && bit_cnt < WIDTH-1) begin
            next_bit_cnt = bit_cnt + 1;
        end
        else if (curr_state == DONE) begin
            next_done = 1;
            next_state = IDLE;
        end
        else begin
            next_state = IDLE;
        end
    end

    always @(posedge clk) begin
        curr_state <= next_state;
        bit_cnt <= next_bit_cnt;
        done <= next_done;
        equal <= next_equal;
    end
endmodule