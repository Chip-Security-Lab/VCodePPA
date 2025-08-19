//SystemVerilog
module wave12_glitch #(
    parameter WIDTH = 8,
    parameter GLITCH_PERIOD = 20
)(
    input  wire             clk,
    input  wire             rst,
    output wire [WIDTH-1:0] wave_out
);
    reg [WIDTH-1:0] main_cnt;
    reg glitch;
    
    // 多级缓冲结构，第一级缓冲
    reg [1:0] glitch_buffer_lvl1;
    // 第二级缓冲，每个first级缓冲驱动两个second级缓冲
    reg [3:0] glitch_buffer_lvl2;
    // 输出缓冲寄存器，减轻wave_out的负载
    reg [WIDTH-1:0] wave_out_reg;
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            main_cnt <= 0;
            glitch <= 0;
            glitch_buffer_lvl1 <= 2'b00;
            glitch_buffer_lvl2 <= 4'b0000;
            wave_out_reg <= {WIDTH{1'b0}};
        end else begin
            main_cnt <= main_cnt + 1;
            
            if(main_cnt == GLITCH_PERIOD) 
                glitch <= ~glitch;
            
            // 第一级缓冲更新
            glitch_buffer_lvl1 <= {2{glitch}};
            
            // 第二级缓冲更新，每个first级缓冲驱动两个second级
            glitch_buffer_lvl2[1:0] <= {2{glitch_buffer_lvl1[0]}};
            glitch_buffer_lvl2[3:2] <= {2{glitch_buffer_lvl1[1]}};
            
            // 更新输出寄存器，平衡负载
            wave_out_reg[WIDTH/4-1:0]         <= {(WIDTH/4){glitch_buffer_lvl2[0]}};
            wave_out_reg[WIDTH/2-1:WIDTH/4]   <= {(WIDTH/4){glitch_buffer_lvl2[1]}};
            wave_out_reg[3*WIDTH/4-1:WIDTH/2] <= {(WIDTH/4){glitch_buffer_lvl2[2]}};
            wave_out_reg[WIDTH-1:3*WIDTH/4]   <= {(WIDTH/4){glitch_buffer_lvl2[3]}};
        end
    end
    
    // 使用寄存器输出
    assign wave_out = wave_out_reg;
endmodule