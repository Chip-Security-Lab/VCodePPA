//SystemVerilog
module Timer_PrescaleDown #(parameter DIV=16) (
    input clk, rst_n, load_en,
    input [7:0] init_val,
    output reg timeup
);
    reg [7:0] counter;
    wire ps_cycle_complete;
    
    // 将prescale计数器逻辑放在组合逻辑之后
    reg [$clog2(DIV)-1:0] ps_cnt_next, ps_cnt;
    
    // 优化后的除法实现
    reg [7:0] dividend, dividend_next;
    reg [7:0] divisor;
    reg [3:0] shift_count, shift_count_next;
    reg division_active, division_active_next;
    reg division_done, division_done_next;
    
    // Division state machine
    localparam IDLE = 2'b00;
    localparam DIVIDING = 2'b01;
    localparam DONE = 2'b10;
    reg [1:0] div_state, div_state_next;
    
    // 组合逻辑部分 - 计算下一状态
    always @(*) begin
        // 默认保持当前状态
        div_state_next = div_state;
        dividend_next = dividend;
        shift_count_next = shift_count;
        division_active_next = division_active;
        division_done_next = division_done;
        ps_cnt_next = ps_cnt;
        
        case (div_state)
            IDLE: begin
                if (ps_cnt == 0) begin
                    dividend_next = DIV;
                    shift_count_next = 8;
                    div_state_next = DIVIDING;
                    division_active_next = 1;
                    division_done_next = 0;
                end else begin
                    ps_cnt_next = ps_cnt + 1;
                end
            end
            
            DIVIDING: begin
                if (shift_count > 0) begin
                    if (dividend >= divisor) begin
                        dividend_next = (dividend - divisor) << 1;
                    end else begin
                        dividend_next = dividend << 1;
                    end
                    shift_count_next = shift_count - 1;
                end else begin
                    div_state_next = DONE;
                    division_active_next = 0;
                    division_done_next = 1;
                end
            end
            
            DONE: begin
                division_done_next = 0;
                ps_cnt_next = (ps_cnt == DIV-1) ? 0 : ps_cnt + 1;
                div_state_next = IDLE;
            end
            
            default: div_state_next = IDLE;
        endcase
    end
    
    // 寄存器更新 - 前向重定时后移动到组合逻辑之后
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_state <= IDLE;
            dividend <= 0;
            shift_count <= 0;
            division_active <= 0;
            division_done <= 0;
            ps_cnt <= 0;
            divisor <= DIV;
        end else begin
            div_state <= div_state_next;
            dividend <= dividend_next;
            shift_count <= shift_count_next;
            division_active <= division_active_next;
            division_done <= division_done_next;
            ps_cnt <= ps_cnt_next;
        end
    end
    
    // 分配prescale周期完成信号
    assign ps_cycle_complete = (ps_cnt == 0);
    
    // 计数器下一状态逻辑
    reg [7:0] counter_next;
    reg timeup_next;
    
    always @(*) begin
        counter_next = counter;
        timeup_next = (counter == 0);
        
        if (load_en) begin
            counter_next = init_val;
            timeup_next = 0;
        end else if (ps_cycle_complete && counter > 0) begin
            counter_next = counter - 1;
        end
    end
    
    // 主计数器寄存器 - 重定时后移到组合逻辑之后
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            timeup <= 0;
        end else begin
            counter <= counter_next;
            timeup <= timeup_next;
        end
    end
endmodule