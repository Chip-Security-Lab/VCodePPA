//SystemVerilog
module wave12_glitch #(
    parameter WIDTH = 8,
    parameter GLITCH_PERIOD = 20
)(
    input  wire             clk,
    input  wire             rst,
    output reg  [WIDTH-1:0] wave_out
);
    reg [$clog2(GLITCH_PERIOD+1)-1:0] main_cnt;
    reg glitch;
    reg glitch_pipe;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            main_cnt <= 0;
            glitch <= 0;
            glitch_pipe <= 0;
            wave_out <= 0;
        end else begin
            if(main_cnt == GLITCH_PERIOD) begin
                main_cnt <= 0;
                glitch <= ~glitch;
            end else begin
                main_cnt <= main_cnt + 1'b1;
            end
            
            glitch_pipe <= glitch;
            
            // 使用条件赋值简化位复制操作
            wave_out <= {WIDTH{glitch_pipe}};
        end
    end
endmodule