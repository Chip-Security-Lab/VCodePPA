//SystemVerilog
module debounce_ismu #(parameter CNT_WIDTH = 4)(
    input wire clk, rst,
    input wire [7:0] raw_intr,
    output reg [7:0] stable_intr
);
    reg [7:0] intr_r1, intr_r2;
    reg [CNT_WIDTH-1:0] counter [7:0];
    integer i;
    
    // 状态定义
    localparam RESET = 2'b00;
    localparam COUNTING = 2'b01;
    localparam STABLE = 2'b10;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_r1 <= 8'h0;
            intr_r2 <= 8'h0;
            stable_intr <= 8'h0;
            for (i = 0; i < 8; i = i + 1)
                counter[i] <= 0;
        end else begin
            intr_r1 <= raw_intr;
            intr_r2 <= intr_r1;
            
            for (i = 0; i < 8; i = i + 1) begin
                // 定义当前状态
                reg [1:0] current_state;
                
                if (intr_r1[i] != intr_r2[i])
                    current_state = RESET;
                else if (counter[i] < {CNT_WIDTH{1'b1}})
                    current_state = COUNTING;
                else
                    current_state = STABLE;
                    
                // 使用case语句替代if-else级联结构
                case (current_state)
                    RESET: begin
                        counter[i] <= 0;
                    end
                    
                    COUNTING: begin
                        counter[i] <= counter[i] + 1;
                    end
                    
                    STABLE: begin
                        stable_intr[i] <= intr_r1[i];
                    end
                    
                    default: begin
                        counter[i] <= counter[i];
                    end
                endcase
            end
        end
    end
endmodule