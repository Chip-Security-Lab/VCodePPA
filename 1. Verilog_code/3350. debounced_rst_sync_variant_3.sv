//SystemVerilog
module debounced_rst_sync #(
    parameter DEBOUNCE_LEN = 8
)(
    input  wire clk,
    input  wire noisy_rst_n,
    output wire clean_rst_n
);
    reg noisy_rst_n_ff;
    reg [1:0] sync_flops;
    reg [3:0] debounce_counter;
    reg clean_rst_n_reg;
    
    // 前向寄存器重定时：将输入寄存化，减少输入端到第一级寄存器的延迟
    always @(posedge clk) begin
        noisy_rst_n_ff <= noisy_rst_n;
    end
    
    // 后向寄存器重定时：将输出寄存器向前移动穿过组合逻辑，平衡路径延迟
    wire should_reset;
    wire counter_max;
    
    assign counter_max = (debounce_counter == DEBOUNCE_LEN-1);
    assign should_reset = (sync_flops[1] == 1'b0) && counter_max;
    assign clean_rst_n = clean_rst_n_reg;
    
    always @(posedge clk) begin
        sync_flops <= {sync_flops[0], noisy_rst_n_ff};
        
        if (sync_flops[1] == 1'b0) begin
            if (!counter_max)
                debounce_counter <= debounce_counter + 1;
        end else begin
            debounce_counter <= 0;
        end
        
        if (should_reset)
            clean_rst_n_reg <= 1'b0;
        else if (sync_flops[1] == 1'b1)
            clean_rst_n_reg <= 1'b1;
    end
endmodule