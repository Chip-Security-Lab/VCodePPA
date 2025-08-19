//SystemVerilog
module priority_fixed_ismu #(parameter INT_COUNT = 16)(
    input clk, reset,
    input [INT_COUNT-1:0] int_src,
    input [INT_COUNT-1:0] int_enable,
    output reg [3:0] priority_num,
    output reg int_active
);
    // 生成有效中断信号
    wire [INT_COUNT-1:0] valid_int = int_src & int_enable;
    reg [3:0] next_priority;
    reg next_active;
    
    always @(*) begin
        next_active = 1'b0;
        next_priority = 4'h0;
        
        if (valid_int[0]) begin
            next_priority = 4'h0; next_active = 1'b1;
        end else if (valid_int[1]) begin
            next_priority = 4'h1; next_active = 1'b1;
        end else if (valid_int[2]) begin
            next_priority = 4'h2; next_active = 1'b1;
        end else if (valid_int[3]) begin
            next_priority = 4'h3; next_active = 1'b1;
        end else if (valid_int[4]) begin
            next_priority = 4'h4; next_active = 1'b1;
        end else if (valid_int[5]) begin
            next_priority = 4'h5; next_active = 1'b1;
        end else if (valid_int[6]) begin
            next_priority = 4'h6; next_active = 1'b1;
        end else if (valid_int[7]) begin
            next_priority = 4'h7; next_active = 1'b1;
        end else if (valid_int[8]) begin
            next_priority = 4'h8; next_active = 1'b1;
        end else if (valid_int[9]) begin
            next_priority = 4'h9; next_active = 1'b1;
        end else if (valid_int[10]) begin
            next_priority = 4'ha; next_active = 1'b1;
        end else if (valid_int[11]) begin
            next_priority = 4'hb; next_active = 1'b1;
        end else if (valid_int[12]) begin
            next_priority = 4'hc; next_active = 1'b1;
        end else if (valid_int[13]) begin
            next_priority = 4'hd; next_active = 1'b1;
        end else if (valid_int[14]) begin
            next_priority = 4'he; next_active = 1'b1;
        end else if (valid_int[15]) begin
            next_priority = 4'hf; next_active = 1'b1;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            priority_num <= 4'h0;
            int_active <= 1'b0;
        end else begin
            priority_num <= next_priority;
            int_active <= next_active;
        end
    end
endmodule