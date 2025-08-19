//SystemVerilog
module DoubleBufferTimer #(parameter DW=8) (
    input clk, rst_n,
    input [DW-1:0] next_period,
    output reg [DW-1:0] current
);
    reg [DW-1:0] buffer;
    reg [DW-1:0] decremented_value;
    reg borrow;
    integer i;
    
    // Conditional inverted subtraction algorithm implementation
    always @(*) begin
        borrow = 1'b1; // Initialize borrow for subtraction by 1
        decremented_value = current;
        
        for (i = 0; i < DW; i = i + 1) begin
            if (borrow) begin
                decremented_value[i] = ~current[i];
                borrow = current[i];
            end
            else begin
                decremented_value[i] = current[i];
                borrow = 1'b0;
            end
        end
    end
    
    always @(posedge clk) begin
        case ({!rst_n, current == 0})
            2'b10: begin  // 复位状态
                current <= {DW{1'b0}};
                buffer <= {DW{1'b0}};
            end
            2'b01: begin  // 计数器为0，更新周期
                current <= buffer;
                buffer <= next_period;
            end
            2'b00: begin  // 正常计数
                current <= decremented_value;
            end
            default: begin  // 复位状态 (2'b11)
                current <= {DW{1'b0}};
                buffer <= {DW{1'b0}};
            end
        endcase
    end
endmodule