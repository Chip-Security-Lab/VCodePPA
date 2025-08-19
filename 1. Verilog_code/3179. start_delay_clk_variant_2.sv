//SystemVerilog
module start_delay_clk(
    input clk_i,
    input rst_i,
    input [7:0] delay,
    output reg clk_o
);
    reg [7:0] delay_counter;
    reg [3:0] div_counter;
    reg started;
    
    // 状态定义
    localparam RESET = 2'b00;
    localparam DELAY = 2'b01;
    localparam RUNNING = 2'b10;
    
    // 状态变量
    reg [1:0] state;
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            delay_counter <= 8'd0;
            div_counter <= 4'd0;
            clk_o <= 1'b0;
            started <= 1'b0;
            state <= RESET;
        end else begin
            case (state)
                RESET: begin
                    state <= DELAY;
                end
                
                DELAY: begin
                    if (delay_counter >= delay) begin
                        started <= 1'b1;
                        delay_counter <= 8'd0;
                        state <= RUNNING;
                    end else begin
                        delay_counter <= delay_counter + 8'd1;
                    end
                end
                
                RUNNING: begin
                    if (div_counter == 4'd9) begin
                        div_counter <= 4'd0;
                        clk_o <= ~clk_o;
                    end else begin
                        div_counter <= div_counter + 4'd1;
                    end
                end
                
                default: begin
                    state <= RESET;
                end
            endcase
        end
    end
endmodule