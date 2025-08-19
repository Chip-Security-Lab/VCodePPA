//SystemVerilog
module Timer_Cascade #(parameter STAGES=2) (
    input wire clk, 
    input wire rst, 
    input wire en,
    output wire cascade_done
);
    genvar i, j;
    wire [STAGES:0] carry;
    // Buffer registers for high fan-out signals
    reg [1:0] carry_buf[STAGES:0];
    
    // 简单连接，保持不变
    assign carry[0] = en;
    assign cascade_done = carry[STAGES];
    
    // Buffer registers for high fan-out signals
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (integer k = 0; k < STAGES+1; k = k + 1) begin
                carry_buf[k] <= 2'b00;
            end
        end else begin
            for (integer k = 0; k < STAGES+1; k = k + 1) begin
                carry_buf[k] <= {carry_buf[k][0], carry[k]};
            end
        end
    end
    
    generate 
        for(i=0; i<STAGES; i=i+1) begin: stage
            reg [3:0] cnt;
            wire [3:0] next_cnt;
            wire is_max;
            // Buffer registers for high fan-out is_max signal
            reg [1:0] is_max_buf;
            
            // 使用显式多路复用器结构替代条件表达式
            assign is_max = (cnt == 4'd15);
            assign next_cnt = is_max_buf[0] ? 4'd0 : (cnt + 4'd1);
            
            // Buffer for is_max signal
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    is_max_buf <= 2'b00;
                end else begin
                    is_max_buf <= {is_max_buf[0], is_max};
                end
            end
            
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    cnt <= 4'd0;
                end else if (carry_buf[i][0]) begin
                    cnt <= next_cnt;
                end
            end
            
            // 使用显式多路复用器结构替代条件表达式
            assign carry[i+1] = is_max_buf[1] ? carry_buf[i][1] : 1'b0;
        end
    endgenerate
endmodule