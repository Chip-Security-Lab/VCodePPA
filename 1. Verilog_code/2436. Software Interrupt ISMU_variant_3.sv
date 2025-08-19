//SystemVerilog
module sw_interrupt_ismu(
    input logic clock, reset_n,
    input logic [3:0] hw_int,
    input logic valid,
    input logic [3:0] sw_int_set,
    input logic [3:0] sw_int_clr,
    output logic ready,
    output logic [3:0] combined_int
);
    // 注册信号声明
    logic [3:0] sw_int;
    logic [3:0] sw_int_next;
    logic data_processed;
    logic valid_and_ready;
    
    // 优化控制信号计算
    assign valid_and_ready = valid & ready;
    
    // 优化下一周期sw_int计算
    // 使用位操作优先级特性减少运算步骤
    always_comb begin
        sw_int_next = sw_int;
        if (|sw_int_set) sw_int_next = sw_int | sw_int_set;
        if (|sw_int_clr) sw_int_next = sw_int_next & ~sw_int_clr;
    end
    
    // 主状态更新逻辑
    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            sw_int <= '0;
            combined_int <= '0;
            ready <= 1'b1;
            data_processed <= 1'b0;
        end 
        else begin
            if (valid_and_ready) begin
                sw_int <= sw_int_next;
                combined_int <= hw_int | sw_int_next;
                ready <= 1'b0;
                data_processed <= 1'b1;
            end 
            else if (data_processed) begin
                ready <= 1'b1;
                data_processed <= 1'b0;
            end
        end
    end
endmodule