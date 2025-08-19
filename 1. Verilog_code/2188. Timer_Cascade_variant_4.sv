//SystemVerilog
module Timer_Cascade #(parameter STAGES=2) (
    input wire clk, rst, en,
    output wire cascade_done
);
    genvar i, j;
    wire [STAGES:0] carry;
    reg [STAGES:0] carry_buf [1:0]; // 使用二级寄存器缓冲

    assign carry[0] = en;
    assign cascade_done = carry[STAGES];
    
    // 为高扇出信号carry添加缓冲寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (integer k = 0; k <= STAGES; k = k + 1) begin
                carry_buf[0][k] <= 1'b0;
                carry_buf[1][k] <= 1'b0;
            end
        end else begin
            for (integer k = 0; k <= STAGES; k = k + 1) begin
                carry_buf[0][k] <= carry[k];
                carry_buf[1][k] <= carry_buf[0][k];
            end
        end
    end
    
    generate 
        for(i=0; i<STAGES; i=i+1) begin: stage
            reg [3:0] cnt;
            wire cnt_at_max = (cnt == 4'hF);
            
            wire carry_in = (i % 2 == 0) ? carry_buf[0][i] : carry_buf[1][i]; // 交替使用不同的缓冲寄存器组
            
            always @(posedge clk or posedge rst) begin
                if (rst) 
                    cnt <= 4'b0;
                else if (carry_in) 
                    cnt <= cnt_at_max ? 4'b0 : cnt + 4'b1;
            end
            
            assign carry[i+1] = carry[i] & cnt_at_max;
        end 
    endgenerate
endmodule