//SystemVerilog
module watchdog_timer #(parameter WIDTH = 24)(
    input clk_i, rst_ni, wdt_en_i, feed_i,
    input [WIDTH-1:0] timeout_i,
    output reg timeout_o
);
    reg [WIDTH-1:0] counter;
    reg feed_i_d;
    wire feed_edge;
    
    // 将feed_i寄存器化
    always @(posedge clk_i) begin
        if (!rst_ni)
            feed_i_d <= 1'b0;
        else
            feed_i_d <= feed_i;
    end
    
    // 检测feed信号上升沿
    assign feed_edge = feed_i & ~feed_i_d;
    
    // 主状态机
    always @(posedge clk_i) begin
        if (!rst_ni) begin 
            counter <= {WIDTH{1'b0}}; 
            timeout_o <= 1'b0; 
        end
        else begin
            case ({wdt_en_i, feed_edge})
                2'b10: begin  // 看门狗使能且无喂狗信号
                    counter <= counter + 1'b1;
                    timeout_o <= (counter >= timeout_i) ? 1'b1 : timeout_o;
                end
                2'b11: begin  // 看门狗使能且有喂狗信号
                    counter <= {WIDTH{1'b0}};
                    timeout_o <= timeout_o;
                end
                default: begin  // 看门狗未使能
                    counter <= counter;
                    timeout_o <= timeout_o;
                end
            endcase
        end
    end
endmodule