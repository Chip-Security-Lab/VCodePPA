//SystemVerilog
module wave11_piecewise #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    reg [2:0] state, next_state;
    reg [WIDTH-1:0] next_wave_out;
    
    // 优化的状态和输出逻辑
    always @(*) begin
        // 使用状态直接映射到对应的输出值，避免长串的if-else比较
        case (state)
            3'd0: next_wave_out = 8'd10;
            3'd1: next_wave_out = 8'd50;
            3'd2: next_wave_out = 8'd100;
            3'd3: next_wave_out = 8'd150;
            default: next_wave_out = 8'd200;
        endcase
        
        // 优化状态转换逻辑
        next_state = (state == 3'd4) ? 3'd0 : state + 1'b1;
    end
    
    // 寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 3'd0;
            wave_out <= {WIDTH{1'b0}};
        end else begin
            state <= next_state;
            wave_out <= next_wave_out;
        end
    end
endmodule