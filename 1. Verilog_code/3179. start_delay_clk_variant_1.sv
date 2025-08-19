//SystemVerilog
module start_delay_clk(
    input clk_i,
    input rst_i,
    input [7:0] delay,
    input ready,         // 新增接收方准备好的信号
    output reg valid,    // 新增数据有效信号
    output reg clk_o
);
    reg [7:0] delay_counter;
    reg [3:0] div_counter;
    reg started;
    reg [7:0] delay_reg;
    reg delay_loaded;
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            delay_counter <= 8'd0;
            div_counter <= 4'd0;
            clk_o <= 1'b0;
            started <= 1'b0;
            valid <= 1'b0;
            delay_reg <= 8'd0;
            delay_loaded <= 1'b0;
        end else begin
            // 握手协议处理 - 接收延迟值
            if (!delay_loaded && valid && ready) begin
                delay_reg <= delay;
                delay_loaded <= 1'b1;
                valid <= 1'b0;
            end else if (!delay_loaded && !valid) begin
                valid <= 1'b1;
            end
            
            // 延迟计数逻辑
            if (delay_loaded && !started) begin
                if (delay_counter >= delay_reg) begin
                    started <= 1'b1;
                    delay_counter <= 8'd0;
                end else
                    delay_counter <= delay_counter + 8'd1;
            end
            
            // 时钟分频逻辑
            if (started) begin
                if (div_counter == 4'd9) begin
                    div_counter <= 4'd0;
                    clk_o <= ~clk_o;
                end else
                    div_counter <= div_counter + 4'd1;
            end
        end
    end
endmodule