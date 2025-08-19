//SystemVerilog
module pulse_width_clock_gate (
    input  wire clk_in,
    input  wire trigger,
    input  wire rst_n,
    input  wire [3:0] width,
    output wire clk_out
);
    reg [3:0] counter;
    reg enable;
    
    // 定义状态变量
    reg [1:0] current_state;
    
    // 定义状态编码
    localparam [1:0] RESET_STATE = 2'b00,
                     TRIGGER_STATE = 2'b01,
                     COUNTING_STATE = 2'b10,
                     IDLE_STATE = 2'b11;
    
    // 状态转移逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= RESET_STATE;
            counter <= 4'd0;
            enable <= 1'b0;
        end
        else begin
            case (current_state)
                RESET_STATE: begin
                    current_state <= IDLE_STATE;
                    counter <= 4'd0;
                    enable <= 1'b0;
                end
                
                IDLE_STATE: begin
                    if (trigger) begin
                        current_state <= COUNTING_STATE;
                        counter <= width;
                        enable <= 1'b1;
                    end
                end
                
                COUNTING_STATE: begin
                    if (counter == 4'd1) begin
                        counter <= 4'd0;
                        enable <= 1'b0;
                        current_state <= IDLE_STATE;
                    end
                    else begin
                        counter <= counter - 4'd1;
                    end
                end
                
                default: begin
                    current_state <= IDLE_STATE;
                    counter <= 4'd0;
                    enable <= 1'b0;
                end
            endcase
            
            // 触发检测覆盖状态机
            if (trigger && (current_state != COUNTING_STATE || counter == 4'd0)) begin
                current_state <= COUNTING_STATE;
                counter <= width;
                enable <= 1'b1;
            end
        end
    end
    
    // 门控时钟输出
    assign clk_out = clk_in & enable;
endmodule