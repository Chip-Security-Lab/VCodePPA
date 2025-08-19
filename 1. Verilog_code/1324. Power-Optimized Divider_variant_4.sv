//SystemVerilog
module power_opt_divider (
    input clock_i, nreset_i, enable_i,
    output reg clock_o
);
    reg [2:0] div_cnt;
    reg div_out;
    
    // 使用前馈逻辑实现时钟分频
    always @(posedge clock_i or negedge nreset_i) begin
        if (!nreset_i) begin
            div_cnt <= 3'b000;
            div_out <= 1'b0;
            clock_o <= 1'b0;
        end else if (enable_i) begin
            // 优化比较链，使用==进行比较，避免额外信号
            if (div_cnt == 3'b111) begin
                div_cnt <= 3'b000;
                div_out <= ~div_out;
            end else begin
                div_cnt <= div_cnt + 1'b1;
            end
            
            // 输出逻辑优化，减少逻辑层级
            clock_o <= div_out & enable_i;
        end
    end
endmodule